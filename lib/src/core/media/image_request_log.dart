import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/painting.dart' show BoxFit;

import 'image_bytes_tracker.dart';
import 'image_request.dart';
import 'media_log.dart';

/// The debug byte audit of image sites: each resolved URL goes to
/// [ImageBytesTracker], and each new (decode size, URL) pair is logged once
/// under `ImageBytes` — `logical=… mem=… dpr=… fit=… url=…` — with a warning
/// for a site that knows no size at all (the CDN then sends the original).
/// Off unless [ImageBytesTracker.enabled] (`--dart-define=IMGCACHE_TRACE=true`);
/// callers gate on `kDebugMode` too.
abstract final class ImageRequestLog {
  // (decode size, URL) pairs already logged, so a scroll does not flood the
  // log. Dropped whole at the cap (~150 B a key): re-logging a few URLs costs
  // less than LRU bookkeeping.
  static final Set<String> _logged = <String>{};
  static const int _maxKeys = 5000;

  /// Records [request], made for [url] at [fit] on a [dpr] screen.
  static void onRequest(
    ImageRequest request, {
    required String url,
    required BoxFit fit,
    required double dpr,
  }) {
    if (!kDebugMode || !ImageBytesTracker.enabled) return;
    ImageBytesTracker.track(request.imageUrl);
    if (_logged.length >= _maxKeys) _logged.clear();
    final String mem =
        '${request.memCacheWidth ?? 'src'}x${request.memCacheHeight ?? 'src'}';
    if (_logged.add('$mem|${request.imageUrl}')) {
      MediaLog.line(
        MediaLog.bytes,
        'logical=${_dim(request.siteWidth)}x${_dim(request.siteHeight)} '
        'mem=$mem dpr=${dpr.toStringAsFixed(1)} fit=${fit.name} '
        'url=${request.imageUrl}',
      );
    }
    if (request.siteWidth == null && request.siteHeight == null) {
      MediaLog.line(
        MediaLog.bytes,
        'no size hint for $url: the CDN sends the original. Give the image '
        'a width / height, or a bounded parent the layout can read.',
      );
    }
  }

  static String _dim(double? d) =>
      d != null && d.isFinite ? d.toStringAsFixed(0) : '?';
}
