import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_onboarding_step.dart';
import '../../../domain/entities/assistant_starter.dart';
import 'assistant_onboarding_caption.dart';
import 'assistant_onboarding_cue.dart';
import 'assistant_onboarding_stage.dart';
import 'assistant_onboarding_starters.dart';

/// One step of the tour: its demo on the stage, taking whatever room the
/// words under it leave, and the words — plus ways to start on the last
/// step. Too short a page (landscape, huge text) scrolls instead, with a
/// smaller stage.
class AssistantOnboardingPage extends StatelessWidget {
  const AssistantOnboardingPage({
    super.key,
    required this.step,
    required this.active,
    required this.onCue,
    required this.onStarter,
  });

  final AssistantOnboardingStep step;
  final bool active;
  final ValueChanged<AssistantOnboardingCue> onCue;
  final ValueChanged<AssistantStarter> onStarter;

  static const double _gap = AppSpacing.s16;
  static const double _roomy = AppSize.s300;
  static const double _compactStage = AppSize.s160;

  @override
  Widget build(BuildContext context) {
    final stage = AssistantOnboardingStage(
      step: step,
      active: active,
      onCue: onCue,
    );
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AssistantOnboardingCaption(step: step, active: active),
        if (step.isLast) ...[
          const SizedBox(height: AppSpacing.s12),
          AssistantOnboardingStarters(active: active, onStarter: onStarter),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxHeight >= _roomy
            ? Column(
                children: [
                  Expanded(child: stage),
                  const SizedBox(height: _gap),
                  words,
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: _compactStage, child: stage),
                    const SizedBox(height: _gap),
                    words,
                  ],
                ),
              ),
      ),
    );
  }
}
