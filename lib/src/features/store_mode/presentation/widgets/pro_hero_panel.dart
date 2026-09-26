import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../domain/entities/pro_membership.dart';
import 'pro_hero_arch.dart';
import 'pro_hero_headline.dart';
import 'pro_hero_tone.dart';
import 'pro_wave_clipper.dart';

/// One plan's hero: a full-bleed band with wavy edges, its headline and the
/// bag in the arch, coloured by [ProHeroTone.of] the plan's interval. The
/// panel stays put across plans: the band's gradient tweens into the new
/// tone, the headline re-staggers and the arch redraws in the new colour.
class ProHeroPanel extends StatelessWidget {
  const ProHeroPanel({super.key, required this.plan});

  final ProPlan plan;

  @override
  Widget build(BuildContext context) {
    final tone = ProHeroTone.of(plan.interval);
    return ClipPath(
      clipper: const ProWaveClipper(),
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.page),
        curve: AppMotion.standard,
        decoration: BoxDecoration(gradient: tone.bandGradient),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s40),
            ProHeroHeadline(
              key: ValueKey<String>(plan.id),
              interval: plan.interval,
              tone: tone,
            ),
            const SizedBox(height: AppSpacing.s20),
            ProHeroArch(tone: tone),
          ],
        ),
      ),
    );
  }
}
