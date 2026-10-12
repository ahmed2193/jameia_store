import 'package:flutter/material.dart';

import '../media/image_request.dart';
import 'hero_image_network.dart';
import 'hero_image_placeholder.dart';
import 'hero_image_shape.dart';
import 'hero_retrying_image.dart';

export 'hero_card_image.dart';

/// The single image entry point for feature code (never a raw
/// `Image.network` / `CachedNetworkImage`). Docs: `docs/image_pipeline.md`.
///
/// * No photo ([url] empty): [HeroImagePlaceholder] — the grey tile with the
///   Hero bag — for good.
/// * Otherwise the image key policy: canonical URL → one ladder rung for the
///   painted size × min(dpr, 2) (an axis the caller left out is read from
///   the layout, tight axes only; an explicit [memCacheWidth] /
///   [memCacheHeight] may climb to 2048) → the CDN variant
///   (`?w=&h=&fit=&format=webp`, wire size == decode size), whose URL is the
///   disk key ([cdnUrl] answers it for any site).
/// * Loading, by where the bytes come from (decided once per mount): RAM —
///   painted at once; disk — a still grey box, no fade; another size cached
///   in RAM — that one meanwhile; network — the still box, the branded
///   shimmer after 300 ms, then a fast fade-in.
/// * A failed load retries forever on a jittered backoff behind its
///   placeholder (the broken-image icon is never shown), hopping once to the
///   raw file when the CDN's transform rejects it.
///
/// Clips only when needed: rounded corners (`ClipRRect`), an overflow-prone
/// fit (`ClipRect`), the circle (`ClipOval`); one `RepaintBoundary` a tile.
class HeroImage extends StatelessWidget {
  const HeroImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.isCircular = false,
  }) : _clipOval = false;

  /// Circular avatar variant.
  const HeroImage.circle({super.key, required this.url, required double size})
    : width = size,
      height = size,
      radius = 0,
      fit = BoxFit.cover,
      memCacheWidth = null,
      memCacheHeight = null,
      isCircular = true,
      _clipOval = true;

  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  /// Explicit in-RAM decode width (physical px) — a full-screen viewer's.
  /// `null` → from the painted box × DPR. Snapped to the same ladder.
  final int? memCacheWidth;

  /// Explicit in-RAM decode height (physical px). `null` → from the box.
  final int? memCacheHeight;

  /// A round tile: the loading looks are round too ([HeroImage.circle]).
  final bool isCircular;

  /// Whether this image wraps itself in a [ClipOval] ([HeroImage.circle]).
  final bool _clipOval;

  /// Collapses every pending retry backoff into an immediate retry. Wired to
  /// the reconnect path (`app.dart`): the moment the network returns, every
  /// waiting tile tries again instead of waiting out its backoff (up to
  /// 30 min on the slow tier).
  static void retryAllPendingImages() => HeroRetryingImage.retryAllNow();

  /// The URL a `HeroImage(url:, width:, height:, fit:, memCacheWidth:,
  /// memCacheHeight:)` requests on a [dpr] screen — the same key policy, so a
  /// URL built here hits that tile's cache (a viewer's provider, a
  /// prefetch). A host that does not transform comes back canonical with no
  /// params; an empty [url] stays empty.
  static String cdnUrl({
    required String url,
    required double? width,
    required double? height,
    BoxFit fit = BoxFit.cover,
    double dpr = _defaultDpr,
    int? memCacheWidth,
    int? memCacheHeight,
  }) => ImageRequest.resolve(
    url: url,
    width: width,
    height: height,
    fit: fit,
    dpr: dpr,
    memCacheWidth: memCacheWidth,
    memCacheHeight: memCacheHeight,
  ).imageUrl;

  static const double _defaultDpr = 2;

  // Fits whose painted bitmap stays inside its box, so an outer clip is
  // redundant; fitWidth / fitHeight / none can spill and still need one.
  static bool _fitConfined(BoxFit f) =>
      f == BoxFit.cover ||
      f == BoxFit.contain ||
      f == BoxFit.fill ||
      f == BoxFit.scaleDown;

  @override
  Widget build(BuildContext context) {
    final Widget content = url.isEmpty
        ? const HeroImagePlaceholder()
        : HeroImageNetwork(
            url: url,
            fit: fit,
            width: width,
            height: height,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            shape: HeroImageShape(
              width: width,
              height: height,
              radius: radius,
              circular: isCircular,
            ),
          );
    final Widget image = SizedBox(width: width, height: height, child: content);
    final Widget clipped = radius > 0
        ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: image)
        : !isCircular && !_fitConfined(fit)
        ? ClipRect(child: image)
        : image;
    final Widget boundary = RepaintBoundary(child: clipped);
    return _clipOval ? ClipOval(child: boundary) : boundary;
  }
}
