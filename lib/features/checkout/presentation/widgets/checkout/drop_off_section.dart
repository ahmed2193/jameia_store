import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entities/checkout_draft.dart';
import 'checkout_radio.dart';

/// KeeTa real drop-off tiles using bundle assets:
/// `drop_off_option_selected` / `drop_off_option_unselected`.
/// Text from bytecode: "Hand it to me" / "Leave at a spot".
class DropOffSection extends StatelessWidget {
  const DropOffSection({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final DropOffOption selected;
  final ValueChanged<DropOffOption> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tile(DropOffOption value, String label, String sublabel) {
      final on = value == selected;
      return InkWell(
        onTap: () => onSelect(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          child: Row(
            children: [
              // Real KeeTa drop-off option image (selected/unselected)
              Image.asset(
                on
                    ? KeetaAssets.dropOffSelected
                    : KeetaAssets.dropOffUnselected,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => Icon(
                  on ? Icons.person_rounded : Icons.door_front_door_outlined,
                  size: 24,
                  color: on ? AppColors.primaryText : AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              // Radio — b3caa4 (selected #000) / ieba4d (unselected #666):
              // 16×16, 1.9dp ring; selected adds a filled centre dot.
              CheckoutRadio(selected: on),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s16),
          // Section title: 16dp/w500/#222222, ph:16dp
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
            ),
            child: Text(
              'checkout.dropoff_title'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          tile(
            DropOffOption.handToMe,
            'checkout.dropoff_hand_label'.tr(),
            'checkout.dropoff_hand_sub'.tr(),
          ),
          const ThinDivider(indent: AppSpacing.s16),
          tile(
            DropOffOption.leaveAtSpot,
            'checkout.dropoff_leave_label'.tr(),
            'checkout.dropoff_leave_sub'.tr(),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
      ),
    );
  }
}
