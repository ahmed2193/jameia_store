import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show HttpExceptionWithStatus;

import 'image_body_stalled_exception.dart';

/// How the image retry machine reads a failed load. There is no give-up and
/// no failed-URL blacklist: every failure retries. These only decide the
/// first hop to the raw URL and the transform-broken verdict.
abstract final class ImageLoadFailure {
  // flutter_cache_manager's WebHelper throws `HttpExceptionWithStatus(code,
  // 'Invalid statusCode: code')`; the text is the fallback when the type is
  // wrapped on the way through cached_network_image.
  static final RegExp _status = RegExp(r'statusCode:\s*(\d{3})');
  static const int _firstRejectCode = 400;

  /// The server answered the URL with 4xx / 5xx: a verdict on the URL (an
  /// EXIF-broken transform), unlike a timeout or a socket reset, which says
  /// nothing about the asset and must not poison the registry.
  static bool isServerReject(Object? error) {
    if (error == null) return false;
    if (error is HttpExceptionWithStatus) {
      return error.statusCode >= _firstRejectCode;
    }
    final RegExpMatch? m = _status.firstMatch(error.toString());
    if (m == null) return false;
    return (int.tryParse(m.group(1)!) ?? 0) >= _firstRejectCode;
  }

  /// A body silent for 15 s (the file service's idle timer): a stalled
  /// socket, not a verdict on the URL — no raw hop, no registry entry, the
  /// same variant again on the normal backoff.
  static bool isStalled(Object? error) => error is ImageBodyStalledException;
}
