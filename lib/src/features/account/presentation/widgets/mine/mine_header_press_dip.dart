import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/motion/motion.dart';

/// A part of the Mine header that answers the header's press: while
/// [pressed] it dips to `AppMotion.pressedScale` (in `microPop`, out
/// `fast`, the one press language), around its own centre. The avatar and
/// the name dip; the header's backdrop — the whole top of the screen —
/// holds still (docs/motion App A Mine P1). Reduced motion → no dip.
class MineHeaderPressDip extends StatelessWidget {
  const MineHeaderPressDip({
    super.key,
    required this.pressed,
    required this.child,
  });

  final ValueListenable<bool> pressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MotionGuard.reduced(context);
    return ValueListenableBuilder<bool>(
      valueListenable: pressed,
      builder: (context, down, child) => AnimatedScale(
        scale: down && !reduced ? AppMotion.pressedScale : 1,
        duration: MotionGuard.duration(
          context,
          down ? AppMotion.microPop : AppMotion.fast,
        ),
        curve: AppMotion.signature,
        child: child,
      ),
      child: child,
    );
  }
}
