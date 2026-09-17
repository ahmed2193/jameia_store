import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';
import 'jameia_network_image.dart';
import 'retrying_network_image.dart';

export 'jameia_card_image.dart';

// ---------------------------------------------------------------------------
// There is intentionally NO failed-URL blacklist. The rule is "retry forever,
// never show the broken-image icon for anything that might self-heal" — so no
// per-URL fail stamp drives any decision. The only path that ever shows the
// error tile is the empty-url / asset-not-found case; network failures stay on
// the placeholder and are handled by RetryingNetworkImage's unbounded backoff.
// ---------------------------------------------------------------------------

/// Sized, cached network image with skeleton placeholder + graceful error tile.
/// The single image entry point for feature code (never raw `Image.network`).
///
/// Internally: applies a responsive CDN transform (`media.jm3eia.com`), sizes
/// the in-RAM decode to the painted box × DPR, and retries network failures
/// forever on an exponential backoff while keeping the placeholder visible —
/// the broken-image icon is never shown for a remote URL while mounted.
class JameiaImage extends StatelessWidget {
  const JameiaImage({
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
  const JameiaImage.circle({super.key, required this.url, required double size})
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

  /// Explicit in-RAM decode width override. `null` → auto from box × DPR.
  final int? memCacheWidth;

  /// Explicit in-RAM decode height override. `null` → auto from box × DPR.
  final int? memCacheHeight;

  /// Circular clip (used by [JameiaImage.circle]). Drives the circular
  /// placeholder/error.
  final bool isCircular;

  /// Whether this image wraps itself in a [ClipOval] ([JameiaImage.circle]).
  final bool _clipOval;

  /// Collapses every pending soft-failure retry timer into an immediate retry.
  /// Wire into the reconnect / app-resume path so the moment the network
  /// returns, every grey tile re-attempts at once instead of waiting out its
  /// individual backoff (up to 30 min on the slow tier).
  static void retryAllPendingImages() {
    RetryingNetworkImage.retryAllNow();
  }

  static bool _hasUsableDim(double? d) => d != null && d.isFinite && d > 0;

  // Fits whose painted bitmap is guaranteed to stay inside its box, so an outer
  // clip is redundant. fitWidth/fitHeight/none can spill and still need a clip.
  static bool _fitConfined(BoxFit f) =>
      f == BoxFit.cover ||
      f == BoxFit.contain ||
      f == BoxFit.fill ||
      f == BoxFit.scaleDown;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    Widget content;
    if (url.isEmpty) {
      content = Container(
        color: AppColors.smallBackground,
        width: width,
        height: height,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: AppColors.disabledText,
          size: AppSize.s28,
        ),
      );
    } else if (!_hasUsableDim(width) && !_hasUsableDim(height)) {
      // No usable explicit size — discover the painted area via LayoutBuilder so
      // the CDN transform + decode sizing still fire for layout-driven tiles
      // (Expanded, AspectRatio, …) instead of fetching the original.
      content = LayoutBuilder(
        builder: (ctx, constraints) {
          final layoutW =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : null;
          final layoutH =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : null;
          return JameiaNetworkImage(
            url: url,
            width: width,
            height: height,
            effectiveWidth: layoutW,
            effectiveHeight: layoutH,
            fit: fit,
            dpr: dpr,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
          );
        },
      );
    } else {
      content = JameiaNetworkImage(
        url: url,
        width: width,
        height: height,
        effectiveWidth: _hasUsableDim(width) ? width : null,
        effectiveHeight: _hasUsableDim(height) ? height : null,
        fit: fit,
        dpr: dpr,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
      );
    }

    final image = SizedBox(width: width, height: height, child: content);

    // Clip ONLY when needed: rounded corners (ClipRRect) or an overflow-prone
    // fit (cheaper ClipRect). The common sharp-cornered cover/contain tile skips
    // the clip entirely. isCircular is handled by the [JameiaImage.circle]
    // ClipOval wrapper.
    final Widget clipped;
    if (radius > 0) {
      clipped = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image,
      );
    } else if (!isCircular && !_fitConfined(fit)) {
      clipped = ClipRect(child: image);
    } else {
      clipped = image;
    }

    // Isolate image repaints from the surrounding list tile.
    final boundary = RepaintBoundary(child: clipped);
    return _clipOval ? ClipOval(child: boundary) : boundary;
  }
}
