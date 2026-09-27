import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../core/motion/motion.dart';
import '../../../../../../core/motion/spring_curve.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_skill.dart';
import 'assistant_onboarding_skill_chip.dart';

/// A skill chip bursting out of the waving hand to its spot, one after
/// another by [order], then bobbing a little while the demo ends — still
/// once [progress] reaches `1`.
class AssistantOnboardingSkillBurst extends StatelessWidget {
  const AssistantOnboardingSkillBurst({
    super.key,
    required this.skill,
    required this.order,
    required this.progress,
    required this.from,
  });

  final AssistantOnboardingSkill skill;
  final int order;
  final double progress;

  /// Where the chips burst out from (the hand).
  final AlignmentDirectional from;

  static const double _firstAt = 0.18;
  static const double _step = 0.07;
  static const double _length = 0.26;
  static const double _floatFrom = 0.62;
  static const double _bobs = 1.5;
  static const double _bobReach = AppSize.s4;

  @override
  Widget build(BuildContext context) {
    final start = _firstAt + _step * order;
    final travel = progress.span(
      start,
      start + _length,
      AppMotion.emphasizedDecelerate,
    );
    final pop = progress.span(start, start + _length, AppSprings.snappy);
    final float = progress.span(_floatFrom, 1, Curves.linear);
    final phase = order / AssistantOnboardingSkill.values.length;
    final bob =
        math.sin((float * _bobs + phase) * 2 * math.pi) *
        _bobReach *
        (1 - float);
    return Align(
      alignment: AlignmentDirectional.lerp(from, skill.spot, travel)!,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: Transform.scale(
          scale: pop,
          child: AssistantOnboardingSkillChip(skill: skill),
        ),
      ),
    );
  }
}
