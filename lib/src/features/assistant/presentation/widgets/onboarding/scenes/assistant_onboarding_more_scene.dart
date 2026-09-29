import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/motion/motion.dart';
import '../assistant_onboarding_cue.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_discount_tag.dart';
import 'assistant_onboarding_feature_row.dart';
import 'assistant_onboarding_progress_bar.dart';
import 'assistant_onboarding_slot_chip.dart';

/// Deals, orders and delivery: three answers slide in one after another
/// while the mascot talks — a deal gets its tag, the order's track fills
/// towards the door, a delivery slot is booked — and it smiles.
class AssistantOnboardingMoreScene extends StatelessWidget {
  const AssistantOnboardingMoreScene({
    super.key,
    required this.active,
    this.played = false,
    required this.onCue,
  });

  final bool active;

  /// Its demo already played in this opening of the tour: its end, at once.
  final bool played;
  final ValueChanged<AssistantOnboardingCue> onCue;

  static const Duration _length = Duration(milliseconds: 3000);
  static const List<AssistantOnboardingBeat> _beats = [
    (0.04, AssistantOnboardingCue.talk),
    (0.66, AssistantOnboardingCue.smile),
  ];
  static const double _rowStep = 0.12;
  static const double _rowLength = 0.34;
  static const double _tagFrom = 0.5;
  static const double _tagTo = 0.7;
  static const double _trackFrom = 0.55;
  static const double _trackTo = 0.95;

  /// How far along the demo order is.
  static const double _trackValue = 0.72;
  static const double _slotFrom = 0.66;
  static const double _slotTo = 0.86;

  @override
  Widget build(BuildContext context) {
    return AssistantOnboardingTimeline(
      active: active,
      played: played,
      length: _length,
      beats: _beats,
      onCue: onCue,
      builder: (context, t) {
        double row(int index) => t.span(
          _rowStep * index,
          _rowStep * index + _rowLength,
          AppMotion.emphasizedDecelerate,
        );
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AssistantOnboardingFeatureRow(
                icon: Icons.local_offer_rounded,
                color: AppColors.accent1,
                tint: AppColors.accent1Light,
                title: 'assistant.onboarding_demo_offer'.tr(),
                subtitle: 'assistant.onboarding_demo_offer_note'.tr(),
                appear: row(0),
                trailing: AssistantOnboardingDiscountTag(
                  appear: t.span(_tagFrom, _tagTo, AppSprings.snappy),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              AssistantOnboardingFeatureRow(
                icon: Icons.local_shipping_rounded,
                color: AppColors.link,
                tint: AppColors.accentSkyLight,
                title: 'assistant.onboarding_demo_order'.tr(),
                subtitle: 'assistant.onboarding_demo_order_status'.tr(),
                appear: row(1),
                trailing: AssistantOnboardingProgressBar(
                  value:
                      t.span(
                        _trackFrom,
                        _trackTo,
                        AppMotion.emphasizedDecelerate,
                      ) *
                      _trackValue,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              AssistantOnboardingFeatureRow(
                icon: Icons.schedule_rounded,
                color: AppColors.primaryDark,
                tint: AppColors.brandLightBg,
                title: 'assistant.onboarding_demo_delivery'.tr(),
                subtitle: 'assistant.onboarding_demo_slot_note'.tr(),
                appear: row(2),
                trailing: AssistantOnboardingSlotChip(
                  appear: t.span(_slotFrom, _slotTo, AppSprings.snappy),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
