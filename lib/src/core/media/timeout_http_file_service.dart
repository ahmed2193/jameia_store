import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import 'disk_indexing_response.dart';
import 'image_load_trace.dart';
import 'image_net_activity.dart';

/// The image store's file service: [HttpFileService] plus a header timeout,
/// so a stalled connection can't leave an image stuck on its placeholder
/// forever, and a [DiskIndexingResponse] around every answer (disk index,
/// net-activity lease, body-idle stall).
class TimeoutHttpFileService extends HttpFileService {
  TimeoutHttpFileService({super.httpClient});

  /// 25 s — long enough that a slow CDN handshake on 3G cold-start doesn't
  /// time out and mass-fail URLs; short enough that a truly dead socket gives
  /// up and lets the retry loop reschedule.
  static const Duration headerTimeout = Duration(seconds: 25);

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode && ImageLoadTrace.enabled) ImageLoadTrace.onNetworkGet(url);
    // A screen's GET (not the prefetcher's) holds the prefetch gate shut.
    final ImageGetLease? lease = ImageNetActivity.begin(url);
    try {
      final FileServiceResponse r = await super
          .get(url, headers: headers)
          .timeout(
            headerTimeout,
            onTimeout: () => throw http.ClientException(
              'Image download timed out after ${headerTimeout.inSeconds}s',
              Uri.parse(url),
            ),
          );
      return DiskIndexingResponse(r, url, lease);
    } catch (_) {
      lease?.end();
      rethrow;
    }
  }
}
