import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/motion/motion.dart';
import '../../domain/entities/pro_membership.dart';
import 'pro_hero_arch.dart';
import 'pro_hero_headline.dart';
import 'pro_hero_tone.dart';
import 'pro_wave_clipper.dart';

/// One plan's hero: a full-bleed band with wavy edges, its headline and the
/// bag in the arch, coloured by [ProHeroTone.of] the plan's interval. The
/// panel stays put across plans and answers a switch with one quiet change
/// (backlog B2-03): the band's gradient tweens into the new tone, new words
/// cross-fade over the old ones (the lines rise in only when the hero first
/// shows), and the arch recolours in place (it draws itself only once).
class ProHeroPanel extends StatefulWidget {
  const ProHeroPanel({super.key, required this.plan});

  final ProPlan plan;

  @override
  State<ProHeroPanel> createState() => _ProHeroPanelState();
}

class _ProHeroPanelState extends State<ProHeroPanel> {
  /// Another plan has been shown here: its words cross-fade in.
  bool _switched = false;

  @override
  void didUpdateWidget(ProHeroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.id != widget.plan.id) _switched = true;
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final tone = ProHeroTone.of(plan.interval);
    return ClipPath(
      clipper: const ProWaveClipper(),
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.page),
        curve: AppMotion.signature,
        decoration: BoxDecoration(gradient: tone.bandGradient),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s40),
            FadeThroughSwitcher(
              stateKey: plan.interval,
              crossFade: true,
              child: ProHeroHeadline(
                interval: plan.interval,
                tone: tone,
                entrance: !_switched,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            ProHeroArch(tone: tone),
          ],
        ),
      ),
    );
  }
}
