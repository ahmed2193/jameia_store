import 'package:flutter/widgets.dart';

import '../../../../core/design/jameia_cart_mark.dart';
import '../../../../core/motion/haptics.dart';
import 'splash_choreography.dart';
import 'splash_layout.dart';
import 'splash_touch.dart';

/// Feeds the finger to [touch]: where it lands (and whether that was the
/// cart, which then hops with a light haptic), where it moves, when it
/// lifts. Passes [child] through untouched when [touch] is `null` (reduced
/// motion).
class SplashTouchSurface extends StatelessWidget {
  const SplashTouchSurface({
    super.key,
    required this.clock,
    required this.choreography,
    required this.touch,
    required this.child,
  });

  final Animation<double> clock;
  final SplashChoreography choreography;
  final SplashTouch? touch;
  final Widget child;

  /// Extra hit area around the cart for a tap, in dp.
  static const double cartHitSlop = 16;

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
    final layout = SplashLayout(size);
    final frame = choreography.frameAt(
      clock.value * choreography.duration.inMilliseconds,
      layout,
    );
    final bounds = JameiaCartMark.bounds;
    final onCart = Rect.fromCenter(
      center: frame.cartCenter,
      width: bounds.width * frame.cartUnit,
      height: bounds.height * frame.cartUnit,
    ).inflate(cartHitSlop).contains(position);
    if (onCart) Haptics.tap();
    touch.down(position, layout.center, onCart: onCart);
  }
}
