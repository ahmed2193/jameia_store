import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import 'hero_map.dart';

/// A marker bitmap, the point of it that sits on the map's position (0 → 1
/// across and down the bitmap) and its logical size on screen (before the
/// pixel-ratio scale), so a camera can keep the whole marker in its frame.
typedef HeroMapMarker = ({BitmapDescriptor icon, Offset anchor, Size size});

/// Map markers drawn from the app's SVG art. The native map takes a bitmap,
/// so each SVG is rasterised once — at the screen's pixel density, so it
/// stays crisp — per asset, size and density, and kept for the app's life:
/// a live map never rasterises art while it animates. The bitmap is handed
/// over at that density (`imagePixelRatio`, no logical size), so the native
/// map shows it pixel for pixel instead of rescaling it on every update.
abstract final class HeroMapMarkers {
  static final Map<String, Future<BitmapDescriptor>> _cache =
      <String, Future<BitmapDescriptor>>{};
  static final Map<String, Future<HeroMapMarker>> _labelled =
      <String, Future<HeroMapMarker>>{};

  // The name bubble over a labelled pin: its padding, the gap to the pin,
  // the widest it grows and the room its shadow takes.
  static const double _labelPadX = AppSpacing.s10;
  static const double _labelPadY = AppSpacing.s4;
  static const double _labelGap = AppSpacing.s2;
  static const double _labelMaxWidth = 180;
  static const double _shadowRoom = AppSpacing.s4;
  static const double _shadowElevation = 3;
  static const String _ellipsis = '…';

  /// [asset] as a marker [size] logical pixels big on a screen of
  /// [pixelRatio]. A failed load is forgotten, so the next call tries again.
  static Future<BitmapDescriptor> svg(
    String asset, {
    required Size size,
    required double pixelRatio,
  }) {
    final key = '$asset@${size.width}x${size.height}@$pixelRatio';
    final cached = _cache[key];
    if (cached != null) return cached;
    final loading = _rasterise(asset, size, pixelRatio);
    _cache[key] = loading;
    // A block body: an arrow would hand back the failed future it removed,
    // and `then` would fail with it again, unheard.
    unawaited(
      loading.then<void>(
        (_) {},
        onError: (Object _) {
          _cache.remove(key);
        },
      ),
    );
    return loading;
  }

  /// [asset] as a pin [size] big with [label] in a white bubble over it (a
  /// place named on the map), in [style] and [textDirection]; its anchor is
  /// the pin's tip ([pinTip], on the pin art) and its size is the whole
  /// bubble-and-pin bitmap in logical pixels. Kept like [svg].
  static Future<HeroMapMarker> labelledPin(
    String asset, {
    required Size size,
    required Offset pinTip,
    required String label,
    required TextStyle style,
    required TextDirection textDirection,
    required double pixelRatio,
  }) {
    final key =
        '$asset@${size.width}x${size.height}@$pixelRatio|$label|'
        '${textDirection.name}|${style.hashCode}';
    final cached = _labelled[key];
    if (cached != null) return cached;
    final loading = _rasteriseLabelled(
      asset,
      size,
      pinTip,
      label,
      style,
      textDirection,
      pixelRatio,
    );
    _labelled[key] = loading;
    unawaited(
      loading.then<void>(
        (_) {},
        onError: (Object _) {
          _labelled.remove(key);
        },
      ),
    );
    return loading;
  }

  static Future<HeroMapMarker> _rasteriseLabelled(
    String asset,
    Size size,
    Offset pinTip,
    String label,
    TextStyle style,
    TextDirection textDirection,
    double pixelRatio,
  ) async {
    final art = await vg.loadPicture(SvgAssetLoader(asset), null);
    final text = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: _ellipsis,
    )..layout(maxWidth: _labelMaxWidth);
    try {
      final bubble = Size(
        text.width + _labelPadX * 2,
        text.height + _labelPadY * 2,
      );
      final width = math.max(bubble.width, size.width) + _shadowRoom * 2;
      final pinTop = _shadowRoom + bubble.height + _labelGap;
      final height = pinTop + size.height;
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (width - bubble.width) / 2,
          _shadowRoom,
          bubble.width,
          bubble.height,
        ),
        Radius.circular(bubble.height / 2),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(pixelRatio);
      canvas
        ..drawShadow(
          Path()..addRRect(bubbleRect),
          AppColors.black,
          _shadowElevation,
          false,
        )
        ..drawRRect(bubbleRect, Paint()..color = AppColors.white);
      text.paint(
        canvas,
        Offset(bubbleRect.left + _labelPadX, bubbleRect.top + _labelPadY),
      );
      canvas
        ..save()
        ..translate((width - size.width) / 2, pinTop)
        ..scale(size.width / art.size.width, size.height / art.size.height)
        ..drawPicture(art.picture)
        ..restore();
      final picture = recorder.endRecording();
      // The picture and the image are freed even when rasterising or
      // encoding throws (a lost GPU context while the app is backgrounded).
      final image = await picture
          .toImage((width * pixelRatio).round(), (height * pixelRatio).round())
          .whenComplete(picture.dispose);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) throw StateError('could not encode $asset');
        return (
          icon: BitmapDescriptor.bytes(
            png.buffer.asUint8List(),
            imagePixelRatio: pixelRatio,
          ),
          anchor: Offset(0.5, (pinTop + pinTip.dy * size.height) / height),
          size: Size(width, height),
        );
      } finally {
        image.dispose();
      }
    } finally {
      text.dispose();
      art.picture.dispose();
    }
  }

  static Future<BitmapDescriptor> _rasterise(
    String asset,
    Size size,
    double pixelRatio,
  ) async {
    final art = await vg.loadPicture(SvgAssetLoader(asset), null);
    try {
      final width = (size.width * pixelRatio).round();
      final height = (size.height * pixelRatio).round();
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..scale(width / art.size.width, height / art.size.height)
        ..drawPicture(art.picture);
      final picture = recorder.endRecording();
      final image = await picture
          .toImage(width, height)
          .whenComplete(picture.dispose);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) throw StateError('could not encode $asset');
        return BitmapDescriptor.bytes(
          png.buffer.asUint8List(),
          imagePixelRatio: pixelRatio,
        );
      } finally {
        image.dispose();
      }
    } finally {
      art.picture.dispose();
    }
  }
}
