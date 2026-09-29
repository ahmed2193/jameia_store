import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../mascot/assistant_mascot.dart';
import '../../mascot/assistant_mascot_mood.dart';
import 'assistant_onboarding_phone_screen.dart';
import 'assistant_onboarding_phone_toast.dart';
import 'assistant_onboarding_pulse_ring.dart';

/// The ready demo's little phone: the app in sketch, the assistant's
/// launcher popping into its corner ([launcher]) with a ring pulsing from
/// it ([pulse]) and a hop per [hop], and the greeting dropping in from the
/// top ([toast]).
class AssistantOnboardingPhone extends StatelessWidget {
  const AssistantOnboardingPhone({
    super.key,
    required this.launcher,
    required this.pulse,
    required this.toast,
    required this.hop,
  });

  final double launcher;
  final double pulse;
  final double toast;
  final Object? hop;

  static const double width = AppSize.s120;
  static const double height = AppSize.s200;

  static const double _launcher = AppSize.s28;
  static const double _launcherInset = AppSpacing.s8;
  static const double _launcherBottom = AppSize.s26;
  static const double _toastInset = AppSpacing.s8;
  static const double _toastTop = AppSpacing.s16;
  static const double _toastHidden = -AppSize.s50;
  static const double _rim = AppSize.s3;
  static const BorderRadius _corners = BorderRadius.all(
    Radius.circular(AppRadius.r2),
  );
  static const BoxDecoration _body = BoxDecoration(
    color: AppColors.white,
    borderRadius: _corners,
    boxShadow: AppShadows.medium,
  );
  static const BoxDecoration _frame = BoxDecoration(
    borderRadius: _corners,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.primaryText, width: _rim),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: _body,
        position: DecorationPosition.background,
        child: DecoratedBox(
          decoration: _frame,
          position: DecorationPosition.foreground,
          child: ClipRRect(
            borderRadius: _corners,
            child: Stack(
              children: [
                const Positioned.fill(child: AssistantOnboardingPhoneScreen()),
                PositionedDirectional(
                  start: _toastInset,
                  end: _toastInset,
                  top: lerpDouble(_toastHidden, _toastTop, toast),
                  child: const AssistantOnboardingPhoneToast(),
                ),
                PositionedDirectional(
                  end: _launcherInset,
                  bottom: _launcherBottom,
                  child: SizedBox.square(
                    dimension: _launcher,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: AssistantOnboardingPulseRing(progress: pulse),
                        ),
                        Transform.scale(
                          scale: launcher,
                          child: AssistantMascot(
                            size: _launcher,
                            mood: AssistantMascotMood.happy,
                            outlined: true,
                            cheer: hop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
