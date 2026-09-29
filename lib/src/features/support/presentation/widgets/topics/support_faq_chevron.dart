import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The chevron of a topic header: turns over while the topic is [open].
class SupportFaqChevron extends StatelessWidget {
  const SupportFaqChevron({super.key, required this.open});

  final bool open;

  static const double _openTurns = 0.5;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      turns: open ? _openTurns : 0,
      child: const Icon(
        HeroIcons.arrowDownSmall,
        size: AppSize.s16,
        color: AppColors.tertiaryText,
      ),
    );
  }
}
