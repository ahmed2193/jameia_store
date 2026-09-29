import 'package:flutter/material.dart';

import '../../../../../../core/motion/motion.dart';
import '../assistant_onboarding_cue.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_skill.dart';
import 'assistant_onboarding_skill_burst.dart';
import 'assistant_onboarding_wave.dart';

/// The tour's first demo: the mascot up top waves hello with its sprout, a
/// sparkle pops up on the stage and what the assistant does bursts out
/// around it — find,
/// fill the cart, deals, orders, home and everyday — bobs a moment, and
/// settles.
class AssistantOnboardingHelloScene extends StatelessWidget {
  const AssistantOnboardingHelloScene({
    super.key,
    required this.active,
    this.played = false,
    required this.onCue,
  });

  final bool active;

  /// Its demo already played in this opening of the tour: its end, at once.
  final bool played;
  final ValueChanged<AssistantOnboardingCue> onCue;

  static const Duration _length = Duration(milliseconds: 3200);
  static const List<AssistantOnboardingBeat> _beats = [
    (0.02, AssistantOnboardingCue.wave),
    (0.6, AssistantOnboardingCue.smile),
  ];
  static const AlignmentDirectional _centre = AlignmentDirectional(0, -0.3);
  static const double _popEnd = 0.2;
  static const double _ringTo = 0.5;

  @override
  Widget build(BuildContext context) {
    return AssistantOnboardingTimeline(
      active: active,
      played: played,
      length: _length,
      beats: _beats,
      onCue: onCue,
      builder: (context, t) {
        return Stack(
          children: [
            for (final (order, skill)
                in AssistantOnboardingSkill.values.indexed)
              AssistantOnboardingSkillBurst(
                skill: skill,
                order: order,
                progress: t,
                from: _centre,
              ),
            Align(
              alignment: _centre,
              child: AssistantOnboardingWave(
                pop: t.span(0, _popEnd, AppSprings.snappy),
                ring: t.span(0, _ringTo, AppMotion.linear),
              ),
            ),
          ],
        );
      },
    );
  }
}
