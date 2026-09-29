import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/motion/motion.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../assistant_onboarding_cue.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_hint_chip.dart';
import 'assistant_onboarding_phone.dart';
import 'assistant_onboarding_stage_size.dart';

/// Where to find the assistant: a little phone rises, the launcher pops
/// into its corner and pulses ("tap me anytime") while the mascot up top
/// hops, then the greeting drops in from the top of the phone ("I drop in
/// with ideas").
class AssistantOnboardingReadyScene extends StatelessWidget {
  const AssistantOnboardingReadyScene({
    super.key,
    required this.active,
    this.played = false,
    required this.onCue,
  });

  final bool active;

  /// Its demo already played in this opening of the tour: its end, at once.
  final bool played;
  final ValueChanged<AssistantOnboardingCue> onCue;

  static const Duration _length = Duration(milliseconds: 3400);
  static const List<AssistantOnboardingBeat> _beats = [
    (0.2, AssistantOnboardingCue.cheer),
    (0.58, AssistantOnboardingCue.talk),
    (0.86, AssistantOnboardingCue.smile),
  ];
  static const double _phoneIn = 0.25;
  static const double _phoneRise = AppSize.s24;
  static const double _phoneTop = AppSpacing.s5;
  static const double _launcherFrom = 0.18;
  static const double _launcherTo = 0.34;
  static const double _hopAt = 0.3;
  static const double _pulseFrom = 0.3;
  static const double _pulseTo = 0.82;
  static const int _pulses = 2;
  static const double _tapHintFrom = 0.36;
  static const double _tapHintTo = 0.52;
  static const double _toastFrom = 0.56;
  static const double _toastTo = 0.78;
  static const double _ideaHintFrom = 0.7;
  static const double _ideaHintTo = 0.86;

  /// The notes sit just off the phone's sides, level with what they name.
  static const double _besidePhone =
      (AssistantOnboardingStageSize.width + AssistantOnboardingPhone.width) /
          2 +
      AppSpacing.s6;
  static const double _tapHintBottom = AppSize.s34;
  static const double _ideaHintTop = AppSize.s22;

  @override
  Widget build(BuildContext context) {
    return AssistantOnboardingTimeline(
      active: active,
      played: played,
      length: _length,
      beats: _beats,
      onCue: onCue,
      builder: (context, t) {
        final phone = t.span(0, _phoneIn, AppMotion.emphasizedDecelerate);
        final pulsing = t.span(_pulseFrom, _pulseTo, AppMotion.linear);
        final pulse = pulsing <= 0 || pulsing >= 1
            ? 0.0
            : pulsing * _pulses % 1;
        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: _phoneTop),
                child: Opacity(
                  opacity: phone,
                  child: Transform.translate(
                    offset: Offset(0, (1 - phone) * _phoneRise),
                    child: AssistantOnboardingPhone(
                      launcher: t.span(
                        _launcherFrom,
                        _launcherTo,
                        AppSprings.snappy,
                      ),
                      pulse: pulse,
                      toast: t.span(_toastFrom, _toastTo, AppSprings.snappy),
                      hop: t >= _hopAt ? _hopAt : null,
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: _besidePhone,
              bottom: _tapHintBottom,
              child: AssistantOnboardingHintChip(
                text: 'assistant.onboarding_demo_tap_me'.tr(),
                appear: t.span(_tapHintFrom, _tapHintTo, AppSprings.snappy),
                pointsToEnd: false,
              ),
            ),
            PositionedDirectional(
              end: _besidePhone,
              top: _ideaHintTop,
              child: AssistantOnboardingHintChip(
                text: 'assistant.onboarding_demo_toast'.tr(),
                appear: t.span(_ideaHintFrom, _ideaHintTo, AppSprings.snappy),
                pointsToEnd: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
