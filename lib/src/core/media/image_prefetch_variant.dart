import 'package:flutter/painting.dart' show BoxFit;

import 'image_request.dart';

/// The URL — and so the disk cacheKey — a `HeroImage(url: rawUrl, width:
/// logicalW, height: logicalH, fit: fit)` requests on a [dpr] screen: the
/// widget's own key policy ([ImageRequest.resolve], which `HeroImage.cdnUrl`
/// also answers with: canonical URL, `min(dpr, 2)`, ladder rung, the
/// transform-broken registry). Build every prefetch URL here, never by hand,
/// so the warmed file is the one the destination reads.
String prefetchVariantFor({
  required String rawUrl,
  required double logicalW,
  required double logicalH,
  required BoxFit fit,
  required double dpr,
}) => ImageRequest.resolve(
  url: rawUrl,
  width: logicalW,
  height: logicalH,
  fit: fit,
  dpr: dpr,
).imageUrl;
