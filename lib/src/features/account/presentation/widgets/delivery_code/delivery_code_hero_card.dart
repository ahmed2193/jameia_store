import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/delivery_code_cubit.dart';
import '../settings/settings_card.dart';
import 'delivery_code_badge.dart';
import 'delivery_code_copy_button.dart';
import 'delivery_code_digits.dart';

/// The saved delivery code, big and left-to-right, with what it is for and
/// a copy button.
class DeliveryCodeHeroCard extends StatelessWidget {
  const DeliveryCodeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      radius: AppRadius.r2,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const DeliveryCodeBadge(),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'account.your_delivery_code'.tr(),
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'settings.code_hint'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          BlocSelector<
            DeliveryCodeCubit,
            DeliveryCodeState,
            ({String code, bool changed})
          >(
            // The load is not a change: only a save flips the digits.
            selector: (state) =>
                (code: state.savedCode, changed: state.savedRevision > 0),
            builder: (context, saved) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeliveryCodeDigits(code: saved.code, animate: saved.changed),
                const SizedBox(height: AppSpacing.s16),
                Center(child: DeliveryCodeCopyButton(code: saved.code)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
