import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_assets.dart';
import 'local_alerts.dart';

/// The store pin, the home pin and the rider, decoded.
typedef _Art = (PictureInfo, PictureInfo, PictureInfo);

/// The picture an expanded live card shows, the way delivery apps draw a
/// ride in the notification shade: the store's pin at the start, the home
/// pin at the end, and the track between them filled up to the rider, who
/// rides along it. A wide strip (the shade fits it to its width without
/// cropping), right to left for a right-to-left reader.
abstract final class LocalAlertTrackPicture {
  // The strip, in pixels: wide and short, like the shade's picture slot.
  static const double _width = 1080;
  static const double _height = 300;

  static const double _trackY = 196;
  static const double _trackInset = 110;
  static const double _trackStroke = 16;
  static const Size _pin = Size(84, 100);

  /// Where a pin's tip is on its art (48 × 58, the tip at 53).
  static const double _pinTip = 53 / 58;
  static const double _riderDisc = 58;
  static const double _riderArt = 92;
  static const double _shadowElevation = 6;

  /// The rider keeps clear of the pins at either end.
  static const double _riderClearance = 48;

  /// The rider art rides north; a quarter turn points it along the track.
  static const double _quarterTurn = math.pi / 2;

  /// The store pin, the home pin and the rider, decoded once for every
  /// card the app posts (kept for the app's life, never disposed).
  static Future<_Art>? _art;
  static int _artLoads = 0;

  /// How many times the art was decoded (once, unless a decode failed).
  @visibleForTesting
  static int get artLoads => _artLoads;

  /// The art, decoded on first use; a failed decode is tried again on the
  /// next card.
  static Future<_Art> _artwork() async {
    final art = _art ??= _loadArt();
    try {
      return await art;
    } catch (_) {
      if (identical(_art, art)) _art = null;
      rethrow;
    }
  }

  static Future<_Art> _loadArt() {
    _artLoads++;
    return (
      vg.loadPicture(const SvgAssetLoader(HeroAssets.mapStorePin), null),
      vg.loadPicture(const SvgAssetLoader(HeroAssets.mapHomePin), null),
      vg.loadPicture(const SvgAssetLoader(HeroAssets.mapRider), null),
    ).wait;
  }

  /// [track] as a PNG.
  static Future<Uint8List> render(LocalAlertTrack track) async {
    final (store, home, rider) = await _artwork();
    final rtl = track.rightToLeft;
    final start = rtl ? _width - _trackInset : _trackInset;
    final end = rtl ? _trackInset : _width - _trackInset;
    final along = track.progress.clamp(0, 1).toDouble();
    final riderX = _between(
      start + (end - start) * along,
      start,
      end,
      _riderClearance,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        const Rect.fromLTWH(0, 0, _width, _height),
        Paint()..color = AppColors.brandLightBg,
      );
    final line = Paint()
      ..strokeWidth = _trackStroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        Offset(start, _trackY),
        Offset(end, _trackY),
        line..color = AppColors.white,
      )
      ..drawLine(
        Offset(start, _trackY),
        Offset(riderX, _trackY),
        line..color = AppColors.primary,
      );
    _drawPin(canvas, store, start);
    _drawPin(canvas, home, end);
    final disc = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(riderX, _trackY), radius: _riderDisc),
      );
    canvas
      ..drawShadow(disc, AppColors.black, _shadowElevation, false)
      ..drawPath(disc, Paint()..color = AppColors.white)
      ..save()
      ..translate(riderX, _trackY)
      ..rotate(rtl ? -_quarterTurn : _quarterTurn)
      ..translate(-_riderArt / 2, -_riderArt / 2)
      ..scale(_riderArt / rider.size.width, _riderArt / rider.size.height)
      ..drawPicture(rider.picture)
      ..restore();
    final picture = recorder.endRecording();
    // Both are let go on every path, a failed raster or encode included.
    final image = await picture
        .toImage(_width.round(), _height.round())
        .whenComplete(picture.dispose);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw StateError('could not encode the ride picture');
      return png.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// A pin whose tip sits on the track at [x].
  static void _drawPin(Canvas canvas, PictureInfo art, double x) => canvas
    ..save()
    ..translate(x - _pin.width / 2, _trackY - _pin.height * _pinTip)
    ..scale(_pin.width / art.size.width, _pin.height / art.size.height)
    ..drawPicture(art.picture)
    ..restore();

  /// [x] kept [margin] inside [a] … [b] (either way round).
  static double _between(double x, double a, double b, double margin) {
    final low = math.min(a, b) + margin;
    final high = math.max(a, b) - margin;
    return x.clamp(low, high).toDouble();
  }
}
