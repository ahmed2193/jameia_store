import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart' show BoxFit;

import 'image_cdn_transform.dart';
import 'image_key_policy.dart';

/// What one image site loads: the URL, the raw fallback, the disk cacheKey,
/// the CDN variant and the RAM decode size — the key policy applied ONCE
/// ([ImageRequest.resolve]), so the widget, `HeroImage.cdnUrl` and the
/// prefetcher (`prefetchVariantFor`) can never disagree on a URL.
@immutable
class ImageRequest {
  const ImageRequest({
    required this.imageUrl,
    required this.cacheKey,
    this.fallbackUrl,
    this.variant,
    this.memCacheWidth,
    this.memCacheHeight,
    this.siteWidth,
    this.siteHeight,
  });

  /// [url] at the logical [width] x [height] on a [dpr] screen: canonical URL
  /// → `wireSizeFor` (a `null` axis is unknown and neither sent nor decoded
  /// to — the tight-axis rule; [memCacheWidth] / [memCacheHeight] are the
  /// caller's explicit decode size in physical px, which may climb the
  /// override rungs up to 2048) → [ImageVariant] (recorded in
  /// `ImageVariantIndex`) → the resolved URL, which is also the cacheKey.
  /// [fallbackUrl] is the raw canonical URL whenever the transform changed
  /// it (the EXIF-500 self-heal fetches it under the SAME cacheKey).
  factory ImageRequest.resolve({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    required double dpr,
    int? memCacheWidth,
    int? memCacheHeight,
  }) {
    final ({int? w, int? h}) wire = wireSizeFor(
      logicalW: width,
      logicalH: height,
      pixelW: memCacheWidth,
      pixelH: memCacheHeight,
      dpr: dpr,
    );
    final String canonical = canonicalImageUrl(url);
    final ImageVariant? variant = ImageCdnTransform.variant(
      canonical: canonical,
      wireW: wire.w,
      wireH: wire.h,
      fit: fit,
    );
    final String resolved = ImageCdnTransform.resolve(canonical, variant);
    return ImageRequest(
      imageUrl: resolved,
      cacheKey: resolved,
      fallbackUrl: canonical != resolved ? canonical : null,
      variant: variant,
      memCacheWidth: wire.w,
      memCacheHeight: wire.h,
      siteWidth: width,
      siteHeight: height,
    );
  }

  /// The URL fetched first.
  final String imageUrl;

  /// The disk cache key (and the provider half of the RAM key).
  final String cacheKey;

  /// The raw canonical URL, fetched under [cacheKey] after a failure; `null`
  /// when it is [imageUrl] itself.
  final String? fallbackUrl;

  /// The CDN variant (CDN hosts only): its asset id is where the load policy
  /// looks for another cached size, and its RAM key is cached.
  final ImageVariant? variant;

  /// Decode size in physical px (== the wire size); `null` = not resized.
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// The logical size the request was made for (explicit or adopted from
  /// the layout): the debug trace only.
  final double? siteWidth;
  final double? siteHeight;

  /// The identity of the image a site shows: the asset id on the CDN (every
  /// size and spelling of one asset), else the resolved URL.
  String get assetKey => variant?.assetId ?? imageUrl;
}
