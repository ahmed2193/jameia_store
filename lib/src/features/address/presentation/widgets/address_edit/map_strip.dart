import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// The middle band of a map snapshot ([png], the map's middle = the pin) at
/// [width] × [height] physical pixels, as the map card shows it — what
/// `BoxFit.cover` would show, without keeping the full-height picture in
/// memory. The decode runs off the UI thread; the full picture is dropped
/// as soon as the band is cut. The caller disposes the band.
Future<ui.Image> cutMapStrip(
  Uint8List png, {
  required int width,
  required int height,
}) async {
  final codec = await ui.instantiateImageCodec(png, targetWidth: width);
  try {
    final full = (await codec.getNextFrame()).image;
    try {
      final band = math.min(height, full.height);
      final top = (full.height - band) / 2;
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        full,
        ui.Rect.fromLTWH(0, top, full.width.toDouble(), band.toDouble()),
        ui.Rect.fromLTWH(0, 0, width.toDouble(), band.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(width, band);
      } finally {
        picture.dispose();
      }
    } finally {
      full.dispose();
    }
  } finally {
    codec.dispose();
  }
}
