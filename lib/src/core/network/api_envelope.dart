/// The JSON envelope every non-streaming jm3eia response is wrapped in:
///
/// ```json
/// { "success": true, "statusCode": 200, "statusMessage": "SUCCESS",
///   "results": { ... }, "error": null }
/// ```
///
/// On failure `results` is `null` and `error` carries the localized message
/// plus optional field-level details. `DioConsumer` unwraps this so
/// datasources only ever receive `results`.
///
/// Reference: https://docs.jm3eia.store/developers/conventions.html
class ApiEnvelope {
  const ApiEnvelope({
    required this.success,
    required this.statusCode,
    required this.statusMessage,
    this.results,
    this.error,
  });

  static const String _successKey = 'success';
  static const String _statusCodeKey = 'statusCode';
  static const String _statusMessageKey = 'statusMessage';
  static const String _resultsKey = 'results';
  static const String _errorKey = 'error';

  final bool success;

  /// Mirrors the HTTP status.
  final int statusCode;

  /// Stable enum code (see `ApiStatus`).
  final String statusMessage;

  /// Endpoint-specific payload on success; `null` on failure.
  final Object? results;

  final ApiError? error;

  /// Parses [body] when it has the envelope shape. Returns `null` for anything
  /// else (SSE frames, plain strings, bodies from a non-jm3eia host) so callers
  /// can pass those through untouched.
  static ApiEnvelope? tryParse(Object? body) {
    if (body is! Map) return null;
    final success = body[_successKey];
    final statusMessage = body[_statusMessageKey];
    if (success is! bool || statusMessage is! String) return null;
    final rawError = body[_errorKey];
    return ApiEnvelope(
      success: success,
      statusCode: (body[_statusCodeKey] as num?)?.toInt() ?? 0,
      statusMessage: statusMessage,
      results: body[_resultsKey],
      error: rawError is Map
          ? ApiError.fromJson(rawError.cast<String, dynamic>())
          : null,
    );
  }

  /// Text safe to show a user: the backend's localized message, else the code.
  String get displayMessage {
    final message = error?.message;
    return (message == null || message.isEmpty) ? statusMessage : message;
  }
}

/// The `error` object: `{ "message": "<localized>", "data": [ ...details ] }`.
class ApiError {
  const ApiError({required this.message, this.details = const []});

  static const String _messageKey = 'message';
  static const String _dataKey = 'data';

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final message = json[_messageKey];
    final data = json[_dataKey];
    return ApiError(
      message: message is String ? message : '',
      details: data is List ? List<Object?>.unmodifiable(data) : const [],
    );
  }

  /// Localized, user-displayable text.
  final String message;

  /// Field-level validation details (`error.data`), raw as sent.
  final List<Object?> details;
}
