import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Expand/collapse ACCORDION — the height+fade transition Jameia uses for FAQ
/// rows, checkout sections and marketing rule blocks. Cross-fades between an
/// empty box and [child] while animating size, over [AppMotion.medium] with the
/// signature curve. Reduced-motion → instant show/hide.
class AnimatedAccordion extends StatelessWidget {
  const AnimatedAccordion({
    super.key,
    required this.expanded,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final bool expanded;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: MotionGuard.duration(context, AppMotion.medium),
      curve: AppMotion.signature,
      alignment: alignment,
      child: AnimatedOpacity(
        opacity: expanded ? 1 : 0,
        duration: MotionGuard.duration(context, AppMotion.medium),
        curve: AppMotion.signature,
        child: expanded ? child : const SizedBox(width: double.infinity),
      ),
    );
  }
}
