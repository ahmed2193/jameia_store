import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'splash_choreography.dart';
import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_palette.dart';
import 'splash_scene_painting.dart';
import 'splash_touch.dart';
import 'splash_wordmark.dart';

/// Paints the splash at the [clock]'s current point of the [choreography],
/// with the finger's reactions ([touch]) layered on. Repaints on every clock
/// or touch tick without rebuilding any widget.
class SplashScenePainter extends CustomPainter {
  SplashScenePainter({
    required this.clock,
    required this.choreography,
    required this.wordmark,
    this.touch,
  }) : super(repaint: Listenable.merge([clock, touch]));

  /// 0 → 1 over the choreography's duration.
  final Animation<double> clock;
  final SplashChoreography choreography;

  /// The name the bag delivers.
  final SplashWordmark wordmark;
  final SplashTouch? touch;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = SplashLayout(size, wordmark);
    final ms = clock.value * choreography.duration.inMilliseconds;
    final touch = this.touch;
    var frame = choreography.frameAt(ms, layout);
    if (touch != null) {
      frame = frame.withTouch(
        lift: touch.markLift,
        squash: touch.markSquash,
        wave: touch.capeFlick,
        ripples: touch.ripples,
      );
    }
    final glowShift = touch?.glowShift ?? Offset.zero;
    if (frame.burst < 1) {
      SplashScenePainting.paint(
        canvas,
        size,
        layout,
        frame,
        SplashPalette.onBrand,
        glowShift: glowShift,
      );
    }
    if (frame.burst > 0) _paintBurst(canvas, size, layout, frame, glowShift);
  }

  void _paintBurst(
    Canvas canvas,
    Size size,
    SplashLayout layout,
    SplashFrame frame,
    Offset glowShift,
  ) {
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(
          Rect.fromCircle(
            center: layout.center,
            radius: frame.burst * layout.burstRadius,
          ),
        ),
      );
    SplashScenePainting.paint(
      canvas,
      size,
      layout,
      frame,
      SplashPalette.onWhite,
      glowShift: glowShift,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashScenePainter oldDelegate) =>
      oldDelegate.clock != clock ||
      oldDelegate.choreography != choreography ||
      oldDelegate.wordmark != wordmark ||
      oldDelegate.touch != touch;
}
