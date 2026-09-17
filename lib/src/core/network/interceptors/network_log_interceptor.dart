import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../constants/app_env.dart';
import '../api_envelope.dart';
import '../api_headers.dart';

/// Debug-only trace of every API call — request AND response, so a developer
/// can read exactly what went over the wire without a proxy:
///
/// ```
/// --> #3 POST /v1/auth/verify-otp
///     url: http://10.0.2.2:5055/v1/auth/verify-otp
///     headers:
///       Accept-Language: en
///       X-Assistant-Guest: 3f2a…9c1d
///     body:
///       {
///         "phone": "+96512345678",
///         "code": "1234"
///       }
/// <-- #3 200 POST /v1/auth/verify-otp (61ms) SUCCESS
///     body:
///       { "customer": { … }, "accessToken": "eyJh…Q9zg", … }
/// ```
///
/// Where to read it: `dart:developer` `log` goes to the VM logging stream — the
/// IDE **Debug Console** (VS Code / Android Studio, run with the debugger) and
/// DevTools → Logging, under the `api` name. It does NOT appear in a plain
/// `flutter run` terminal or in logcat.
///
/// Rules:
///   * One log entry per block, so concurrent calls never interleave.
///   * Secrets are masked wherever they travel — header, query, body field,
///     list item — when the key contains `authorization`, `token`, `secret`,
///     `password`, `cookie` or `guest`: first 4 + last 4 chars, or `***` when
///     the value is too short to hide that way. The `url:` line never carries
///     the query string. `--dart-define=API_LOG_SECRETS=true` reveals them.
///   * Bodies are pretty-printed JSON, truncated at [maxBodyChars]; streams
///     (SSE), binary bodies and responses above [maxTraceableBytes] are
///     summarised, never read or encoded.
///   * Lines longer than [maxLineChars] are wrapped.
///   * Tracing can never break a request: any formatting error is swallowed
///     into a one-line note.
///
/// Installed LAST in the chain (`service_locator.dart`) so the request block
/// shows the final headers (Bearer, language, guest ids) and only in
/// `kDebugMode` — a release build carries no trace at all.
class NetworkLogInterceptor extends Interceptor {
  NetworkLogInterceptor({
    this._revealSecrets = AppEnv.apiLogSecrets,
    this._maxBodyChars = defaultMaxBodyChars,
    void Function(String block)? sink,
  }) : _sink = sink ?? _developerLog;

  /// `dart:developer` log name — filter the console on it.
  static const String logName = 'api';

  static const int defaultMaxBodyChars = 4000;

  /// Wrap width; Android logcat truncates single lines past ~1 KB.
  static const int maxLineChars = 800;

  /// Responses whose `Content-Length` exceeds this are not encoded for the
  /// trace at all (masking + pretty-printing a multi-MB catalogue on the UI
  /// isolate would jank the debug build for a block that gets truncated).
  static const int maxTraceableBytes = 256 * 1024;

  static const String _startedAtKey = 'log.startedAt';
  static const String _sequenceKey = 'log.sequence';
  static const String _indent = '    ';
  static const String _truncatedMarker = '… [truncated]';
  static const String _hidden = '***';
  static const int _maskKeep = 4;

  /// Below this length first-4 + last-4 would reveal most of the value.
  static const int _maskMinLength = 16;
  static const List<String> _secretFragments = [
    'authorization',
    'token',
    'secret',
    'password',
    'cookie',
    'guest',
  ];
  static const JsonEncoder _pretty = JsonEncoder.withIndent('  ');

  final bool _revealSecrets;
  final int _maxBodyChars;
  final void Function(String block) _sink;
  int _sequence = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sequence = ++_sequence;
    options.extra[_sequenceKey] = sequence;
    options.extra[_startedAtKey] = DateTime.now();
    _trace(
      () => [
        '--> #$sequence ${options.method} ${options.path}',
        '${_indent}url: ${_withoutQuery(options.uri)}',
        ..._headerLines(options.headers),
        if (options.queryParameters.isNotEmpty)
          '${_indent}query: ${_masked(options.queryParameters)}',
        ..._bodyLines(options.data, isStream: false),
      ],
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    _trace(
      () => [
        '<-- #${_sequenceOf(options)} ${response.statusCode} '
            '${options.method} ${options.path} ${_elapsed(options)} '
            '${_codeOf(response)}',
        ..._responseBodyLines(response),
      ],
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final response = err.response;
    _trace(
      () => [
        'xx  #${_sequenceOf(options)} '
            '${response?.statusCode?.toString() ?? err.type.name} '
            '${options.method} ${options.path} ${_elapsed(options)} '
            '${response == null ? '' : _codeOf(response)}',
        if (response == null) ...[
          '${_indent}type: ${err.type.name}',
          '${_indent}error: ${err.error ?? err.message ?? ''}',
        ] else
          ..._responseBodyLines(response),
      ],
    );
    handler.next(err);
  }

  // ── Formatting ─────────────────────────────────────────────────────────────

  /// Builds and emits one block; a formatting failure becomes a note instead
  /// of an exception inside the interceptor chain.
  void _trace(List<String> Function() buildLines) {
    try {
      _emit(buildLines());
    } on Object catch (error) {
      try {
        _sink('trace skipped: $error');
      } on Object {
        // A broken sink must not break the request either.
      }
    }
  }

  List<String> _headerLines(Map<String, dynamic> headers) {
    if (headers.isEmpty) return const [];
    return [
      '${_indent}headers:',
      for (final entry in headers.entries)
        '$_indent  ${entry.key}: '
            '${_maskIfSecret(entry.key, '${entry.value}')}',
    ];
  }

  List<String> _responseBodyLines(Response<dynamic> response) {
    final length = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
    if (length != null && length > maxTraceableBytes) {
      return ['${_indent}body: <$length bytes — too large to trace>'];
    }
    return _bodyLines(
      response.data,
      isStream: response.requestOptions.responseType == ResponseType.stream,
    );
  }

  List<String> _bodyLines(Object? data, {required bool isStream}) {
    if (data == null) return const [];
    if (isStream) return ['${_indent}body: <stream>'];
    return ['${_indent}body:', ..._formatBody(data).map((l) => '$_indent  $l')];
  }

  List<String> _formatBody(Object? data) {
    if (data is FormData) return _formatFormData(data);
    if (data is List<int>) return ['<${data.length} bytes>'];
    if (data is String) return _truncate(data).split('\n');
    return _truncate(_pretty.convert(_masked(data))).split('\n');
  }

  List<String> _formatFormData(FormData data) => [
    'FormData (${data.fields.length} fields, ${data.files.length} files)',
    for (final field in data.fields)
      '  ${field.key}: ${_maskIfSecret(field.key, field.value)}',
    for (final file in data.files)
      '  ${file.key}: <file ${file.value.filename ?? ''} '
          '${file.value.length} bytes>',
  ];

  /// Deep copy with every secret-named string value masked (list items keep
  /// their parent key, so `pushTokens: [...]` is masked too); non-JSON leaves
  /// are stringified so the encoder never throws.
  Object? _masked(Object? value, [String key = '']) {
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          '${entry.key}': _masked(entry.value, '${entry.key}'),
      };
    }
    if (value is List) {
      return [for (final item in value) _masked(item, key)];
    }
    if (value is String) return _maskIfSecret(key, value);
    if (value == null || value is num || value is bool) return value;
    return value.toString();
  }

  String _maskIfSecret(String key, String value) {
    if (_revealSecrets) return value;
    final lower = key.toLowerCase();
    if (!_secretFragments.any(lower.contains)) return value;
    if (value.startsWith(ApiHeaders.bearerPrefix)) {
      return '${ApiHeaders.bearerPrefix}'
          '${mask(value.substring(ApiHeaders.bearerPrefix.length))}';
    }
    return mask(value);
  }

  /// `eyJhbGci…9ypg` — enough to tell tokens apart, never enough to reuse.
  /// Short values are hidden entirely.
  static String mask(String value) {
    if (value.isEmpty) return '';
    if (value.length < _maskMinLength) return _hidden;
    return '${value.substring(0, _maskKeep)}…'
        '${value.substring(value.length - _maskKeep)}';
  }

  /// The query is printed on its own (masked) line, never inside the URL.
  static String _withoutQuery(Uri uri) => uri.hasQuery
      ? uri.replace(query: '').toString().replaceFirst(RegExp(r'\?$'), '')
      : uri.toString();

  static String _codeOf(Response<dynamic> response) =>
      response.requestOptions.responseType == ResponseType.stream
      ? ''
      : ApiEnvelope.tryParse(response.data)?.statusMessage ?? '';

  String _truncate(String text) => text.length <= _maxBodyChars
      ? text
      : '${text.substring(0, _maxBodyChars)}$_truncatedMarker';

  static String _elapsed(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! DateTime) return '';
    return '(${DateTime.now().difference(startedAt).inMilliseconds}ms)';
  }

  static Object _sequenceOf(RequestOptions options) =>
      options.extra[_sequenceKey] ?? '?';

  /// One log entry per block; long lines wrapped at [maxLineChars].
  void _emit(List<String> lines) {
    final wrapped = <String>[];
    for (final line in lines) {
      if (line.isEmpty) {
        wrapped.add(line);
        continue;
      }
      for (var start = 0; start < line.length; start += maxLineChars) {
        final end = start + maxLineChars;
        wrapped.add(
          line.substring(start, end > line.length ? line.length : end),
        );
      }
    }
    _sink(wrapped.join('\n'));
  }

  static void _developerLog(String block) => log(block, name: logName);
}
