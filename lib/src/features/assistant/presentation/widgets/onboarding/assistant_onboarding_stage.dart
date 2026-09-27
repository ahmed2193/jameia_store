import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_onboarding_step.dart';
import 'assistant_onboarding_cue.dart';
import 'scenes/assistant_onboarding_ask_scene.dart';
import 'scenes/assistant_onboarding_cart_scene.dart';
import 'scenes/assistant_onboarding_hello_scene.dart';
import 'scenes/assistant_onboarding_more_scene.dart';
import 'scenes/assistant_onboarding_ready_scene.dart';
import 'scenes/assistant_onboarding_stage_size.dart';

/// The step's little demo on a soft brand-tinted stage. Demos are laid out
/// in one design box and scaled to the room the page gives them; their text
/// keeps its size inside the box (the caption under the stage follows the
/// customer's text size). Screen readers hear what the demo shows instead.
class AssistantOnboardingStage extends StatelessWidget {
  const AssistantOnboardingStage({
    super.key,
    required this.step,
    required this.active,
    required this.onCue,
  });

  final AssistantOnboardingStep step;
  final bool active;
  final ValueChanged<AssistantOnboardingCue> onCue;

  static const BorderRadius _corners = BorderRadius.all(
    Radius.circular(AppRadius.r2),
  );
  static const BoxDecoration _backdrop = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.brandWash, AppColors.white],
    ),
    borderRadius: _corners,
    border: Border.fromBorderSide(BorderSide(color: AppColors.brandLightBg)),
  );

  @override
  Widget build(BuildContext context) {
    final scene = switch (step) {
      AssistantOnboardingStep.hello => AssistantOnboardingHelloScene(
        active: active,
        onCue: onCue,
      ),
      AssistantOnboardingStep.ask => AssistantOnboardingAskScene(
        active: active,
        onCue: onCue,
      ),
      AssistantOnboardingStep.cart => AssistantOnboardingCartScene(
        active: active,
        onCue: onCue,
      ),
      AssistantOnboardingStep.more => AssistantOnboardingMoreScene(
        active: active,
        onCue: onCue,
      ),
      AssistantOnboardingStep.ready => AssistantOnboardingReadyScene(
        active: active,
        onCue: onCue,
      ),
    };
    return Semantics(
      container: true,
      image: true,
      label: step.sceneKey.tr(),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: _backdrop,
          child: ClipRRect(
            borderRadius: _corners,
            child: SizedBox.expand(
              child: FittedBox(
                child: SizedBox(
                  width: AssistantOnboardingStageSize.width,
                  height: AssistantOnboardingStageSize.height,
                  child: MediaQuery.withNoTextScaling(child: scene),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
