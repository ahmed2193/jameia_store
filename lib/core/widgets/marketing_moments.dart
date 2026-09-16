import 'package:flutter/material.dart';

import '../design/keeta_assets.dart';
import '../motion/motion.dart';

/// Reward-unlock SHINE sweep — overlays KeeTa's invite-reward shimmer GIF
/// ([KeetaAssets.shineGif] / RTL variant) on top of [child] while [active].
/// Picks the RTL asset automatically from the ambient [Directionality].
/// Reduced-motion → no sweep (just the child).
class ShineSweep extends StatelessWidget {
  const ShineSweep({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active || MotionGuard.reduced(context)) return child;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: Image.asset(
                rtl ? KeetaAssets.shineRtlGif : KeetaAssets.shineGif,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Expand/collapse ACCORDION — the height+fade transition KeeTa uses for FAQ
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
