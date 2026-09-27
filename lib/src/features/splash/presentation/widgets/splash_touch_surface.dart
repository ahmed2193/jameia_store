import 'package:flutter/widgets.dart';

import '../../../../core/design/hero_mark.dart';
import '../../../../core/motion/haptics.dart';
import 'splash_choreography.dart';
import 'splash_layout.dart';
import 'splash_touch.dart';
import 'splash_wordmark.dart';

/// Feeds the finger to [touch]: where it lands (and whether that was the
/// bag, which then hops and flicks its cape with a light haptic), where it
/// moves, when it lifts. Passes [child] through untouched when [touch] is `null` (reduced
/// motion).
class SplashTouchSurface extends StatelessWidget {
  const SplashTouchSurface({
    super.key,
    required this.clock,
    required this.choreography,
    required this.wordmark,
    required this.touch,
    required this.child,
  });

  final Animation<double> clock;
  final SplashChoreography choreography;
  final SplashWordmark wordmark;
  final SplashTouch? touch;
  final Widget child;

  /// Extra hit area around the mark for a tap, in dp.
  static const double markHitSlop = 16;

  @override
  Widget build(BuildContext context) {
    final touch = this.touch;
    if (touch == null) return child;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _down(context, touch, event.localPosition),
      onPointerMove: (event) {
        final size = context.size;
        if (size != null) {
          touch.move(event.localPosition, size.center(Offset.zero));
        }
      },
      onPointerUp: (_) => touch.up(),
      onPointerCancel: (_) => touch.up(),
      child: child,
    );
  }

  void _down(BuildContext context, SplashTouch touch, Offset position) {
    final size = context.size;
    if (size == null) return;
    final layout = SplashLayout(size, wordmark);
    final frame = choreography.frameAt(
      clock.value * choreography.duration.inMilliseconds,
      layout,
    );
    final bounds = HeroMark.bounds;
    final onMark = Rect.fromCenter(
      center: frame.markCenter,
      width: bounds.width * frame.markUnit,
      height: bounds.height * frame.markUnit,
    ).inflate(markHitSlop).contains(position);
    if (onMark) Haptics.tap();
    touch.down(position, layout.center, onMark: onMark);
  }
}
