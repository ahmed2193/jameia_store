import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../core/motion/spring_curve.dart';
import '../assistant_onboarding_cue.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_skill.dart';
import 'assistant_onboarding_skill_burst.dart';
import 'assistant_onboarding_wave.dart';

/// The tour's first demo: a hand pops up and waves hello (the mascot up top
/// hops along) and what the assistant does bursts out around it — find,
/// fill the cart, deals, orders, home and everyday — bobs a moment, and
/// settles.
class AssistantOnboardingHelloScene extends StatelessWidget {
  const AssistantOnboardingHelloScene({
    super.key,
    required this.active,
    required this.onCue,
  });

  final bool active;
  final ValueChanged<AssistantOnboardingCue> onCue;

  static const Duration _length = Duration(milliseconds: 3200);
  static const List<AssistantOnboardingBeat> _beats = [
    (0.02, AssistantOnboardingCue.cheer),
    (0.6, AssistantOnboardingCue.smile),
  ];
  static const AlignmentDirectional _centre = AlignmentDirectional(0, -0.3);
  static const double _popEnd = 0.2;
  static const double _waveFrom = 0.06;
  static const double _waveTo = 0.62;
  static const double _waves = 2.5;
  static const double _waveReach = 0.5;
  static const double _ringTo = 0.5;

  @override
  Widget build(BuildContext context) {
    return AssistantOnboardingTimeline(
      active: active,
      length: _length,
      beats: _beats,
      onCue: onCue,
      builder: (context, t) {
        final waving = t.span(_waveFrom, _waveTo, Curves.linear);
        return Stack(
          children: [
            for (final (order, skill) in AssistantOnboardingSkill.values.indexed)
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
                wave:
                    math.sin(waving * _waves * 2 * math.pi) *
                    _waveReach *
                    (1 - waving),
                ring: t.span(0, _ringTo, Curves.linear),
              ),
            ),
          ],
        );
      },
    );
  }
}
