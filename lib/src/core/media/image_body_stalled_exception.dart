import 'package:http/http.dart' as http;

/// A 200/202 image body that went silent for 15 s (`DiskIndexingResponse`).
///
/// A stalled socket says nothing about the URL, so the image widget retries
/// the SAME URL on its normal backoff for this one: no raw-URL hop (that hop
/// answers a failed CDN transform, and would store the full-size original
/// under the variant's cacheKey for a year) and no transform-broken verdict.
/// Every other failure keeps its existing handling. The prefetcher
/// negative-caches it like any other failure.
class ImageBodyStalledException extends http.ClientException {
  ImageBodyStalledException(super.message, [super.uri]);
}
