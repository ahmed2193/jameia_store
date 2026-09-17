import 'package:flutter/material.dart';

import '../design/jameia_assets.dart';
import '../motion/motion.dart';

/// Reward-unlock SHINE sweep — overlays Jameia's invite-reward shimmer GIF
/// ([JameiaAssets.shineGif] / RTL variant) on top of [child] while [active].
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
                rtl ? JameiaAssets.shineRtlGif : JameiaAssets.shineGif,
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
