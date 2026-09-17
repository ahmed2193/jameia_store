import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import 'jameia_cdn_transform.dart';
import 'retrying_network_image.dart';

/// Network branch of [JameiaImage]: resolves the responsive CDN URL (plus the
/// raw fallback), sizes the in-RAM decode to the painted box × DPR and hands
/// off to [RetryingNetworkImage].
///
/// [effectiveWidth]/[effectiveHeight] are the dims used for the CDN transform
/// and decode sizing (explicit constructor args, or what a `LayoutBuilder`
/// discovered). [width]/[height] are the raw explicit args forwarded to the
/// painted image.
class JameiaNetworkImage extends StatelessWidget {
  const JameiaNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.effectiveWidth,
    required this.effectiveHeight,
    required this.fit,
    required this.dpr,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String url;
  final double? width;
  final double? height;
  final double? effectiveWidth;
  final double? effectiveHeight;
  final BoxFit fit;
  final double dpr;

  /// Explicit in-RAM decode width override. `null` → auto from box × DPR.
  final int? memCacheWidth;

  /// Explicit in-RAM decode height override. `null` → auto from box × DPR.
  final int? memCacheHeight;

  /// Debug-only dedup set of `(decodeWxH, url)` keys already logged, so a
  /// scroll doesn't flood the log. Capped to stay bounded over long sessions.
  static final Set<String> _debugLoggedKeys = <String>{};
  static const int _kMaxDebugLogKeys = 5000;

  @override
  Widget build(BuildContext context) {
    // Effective dims: prefer explicit constructor args, fall back to the dims
    // LayoutBuilder discovered. Either way JameiaCdnTransform and _cacheSize see
    // the same numbers so on-wire size and in-RAM decode size agree.
    final effW = effectiveWidth;
    final effH = effectiveHeight;

    const format = 'webp';
    final resolvedUrl = JameiaCdnTransform.apply(
      url: url,
      width: effW,
      height: effH,
      fit: fit,
      dpr: dpr,
      format: format,
    );
    // Raw fallback: slash-normalised URL with NO transform params. When the
    // transform changed the URL we keep this ready so RetryingNetworkImage can
    // switch to it on the first failure — some media.jm3eia.com assets carry a
    // malformed EXIF profile whose transform endpoint 500s while the raw file
    // serves 200, self-healing those tiles app-wide.
    final rawUrl = JameiaCdnTransform.apply(
      url: url,
      width: null,
      height: null,
      fit: fit,
      dpr: dpr,
      format: format,
    );
    final String? fallbackUrl = (rawUrl != resolvedUrl) ? rawUrl : null;

    final cw = memCacheWidth ?? _cacheSize(effW, dpr);
    final ch = memCacheHeight ?? _cacheSize(effH, dpr);

    if (kDebugMode) {
      if (_debugLoggedKeys.length >= _kMaxDebugLogKeys) {
        _debugLoggedKeys.clear();
      }
      final logKey = '${cw ?? "src"}x${ch ?? "src"}|$resolvedUrl';
      if (_debugLoggedKeys.add(logKey)) {
        final logicalW = effW != null && effW.isFinite
            ? effW.toStringAsFixed(0)
            : '?';
        final logicalH = effH != null && effH.isFinite
            ? effH.toStringAsFixed(0)
            : '?';
        log(
          'logical=${logicalW}x$logicalH '
          'mem=${cw ?? "src"}x${ch ?? "src"} '
          'dpr=${dpr.toStringAsFixed(1)} '
          'fit=${fit.name} '
          'url=$resolvedUrl',
          name: 'JameiaImage',
        );
      }
    }

    return RetryingNetworkImage(
      // Key on the resolved URL so a parent that swaps the URL out (variant
      // toggle, banner rotation) gets a fresh retry state; pure rebuilds with
      // the same URL preserve the in-flight retry timer.
      key: ValueKey('cni:$resolvedUrl'),
      imageUrl: resolvedUrl,
      fallbackUrl: fallbackUrl,
      cacheKey: resolvedUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cw,
      memCacheHeight: ch,
      placeholderBuilder: (_) =>
          const ColoredBox(color: AppColors.smallBackground),
    );
  }

  // null when size is null/<=0/non-finite, else size × DPR clamped to [50,900].
  static int? _cacheSize(double? size, double dpr) {
    if (size == null || size <= 0 || size.isInfinite || size.isNaN) return null;
    final effectiveDpr = dpr.clamp(1.0, 2.0);
    return (size * effectiveDpr).round().clamp(50, 900);
  }
}
