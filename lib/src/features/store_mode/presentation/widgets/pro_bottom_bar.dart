import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import 'pro_account_strip.dart';
import 'pro_join_panel.dart';

/// Sticky foot of the loaded paywall, floating over the scrolling content:
/// the Pro-gradient account strip (rounded top, a soft upward shadow) over
/// the trust line and the CTA. Slides up from below once, when the paywall
/// first shows.
class ProBottomBar extends StatelessWidget {
  const ProBottomBar({super.key});

  static const List<BoxShadow> _lift = [
    BoxShadow(
      color: AppColors.shadowInk10,
      offset: Offset(0, -AppSize.s4),
      blurRadius: AppSize.s20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: MotionGuard.duration(context, AppMotion.slow),
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, hidden, child) =>
          FractionalTranslation(translation: Offset(0, hidden), child: child),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.r2),
          ),
          boxShadow: _lift,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [ProAccountStrip(), ProJoinPanel()],
        ),
      ),
    );
  }
}
