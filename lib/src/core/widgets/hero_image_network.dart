import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

import '../media/image_request.dart';
import '../media/image_request_log.dart';
import 'hero_image_shape.dart';
import 'hero_retrying_image.dart';

/// The network branch of `HeroImage`: the image key policy for this site
/// ([ImageRequest.resolve]) and the retrying load, keyed by the ASSET so a
/// size or spelling change of the same image keeps the element.
///
/// An axis the caller did not size is read from the layout — the tight-axis
/// rule: with the other axis fixed, a merely LOOSE bound is not adopted
/// (asking the CDN to crop to a ratio the layout never asked for would make
/// the tile size itself to it); a TIGHT one is the box already, so serving
/// it is free bytes with identical pixels. With neither axis given, any
/// finite bound is the box.
class HeroImageNetwork extends StatelessWidget {
  const HeroImageNetwork({
    super.key,
    required this.url,
    required this.fit,
    required this.shape,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String url;
  final BoxFit fit;
  final HeroImageShape shape;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;

  static bool _usable(double? d) => d != null && d.isFinite && d > 0;

  static double? _adopt(
    double max, {
    required bool tight,
    required bool fixed,
  }) {
    if (!max.isFinite || max <= 0) return null;
    return fixed && !tight ? null : max;
  }

  ImageRequest _request(double dpr, double? layoutW, double? layoutH) {
    final ImageRequest request = ImageRequest.resolve(
      url: url,
      width: _usable(width) ? width : layoutW,
      height: _usable(height) ? height : layoutH,
      fit: fit,
      dpr: dpr,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
    );
    if (kDebugMode) {
      ImageRequestLog.onRequest(request, url: url, fit: fit, dpr: dpr);
    }
    return request;
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final bool haveW = _usable(width);
    final bool haveH = _usable(height);
    if (haveW && haveH) {
      final ImageRequest request = _request(dpr, null, null);
      return HeroRetryingImage(
        key: ValueKey<String>(request.assetKey),
        request: request,
        fit: fit,
        shape: shape,
        width: width,
        height: height,
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ImageRequest request = _request(
          dpr,
          haveW
              ? null
              : _adopt(
                  constraints.maxWidth,
                  tight: constraints.hasTightWidth,
                  fixed: haveH,
                ),
          haveH
              ? null
              : _adopt(
                  constraints.maxHeight,
                  tight: constraints.hasTightHeight,
                  fixed: haveW,
                ),
        );
        return HeroRetryingImage(
          key: ValueKey<String>(request.assetKey),
          request: request,
          fit: fit,
          shape: shape,
          width: width,
          height: height,
        );
      },
    );
  }
}
