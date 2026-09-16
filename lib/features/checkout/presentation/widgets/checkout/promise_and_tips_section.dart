import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';
import 'on_time_promise_sheet.dart';
import 'tip_row.dart';

/// KeeTa groups the on-time promise row and the rider tip row together in the
/// same white section card (separated by a ThinDivider).
class PromiseAndTipsSection extends StatelessWidget {
  const PromiseAndTipsSection({
    super.key,
    required this.tip,
    required this.options,
    required this.onTipSelect,
  });
  final double tip;
  final List<double> options;
  final ValueChanged<double> onTipSelect;

  void _openPromiseSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) => const OnTimePromiseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On-time promise row
          InkWell(
            onTap: () => _openPromiseSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s14,
              ),
              child: Row(
                children: [
                  // Real KeeTa on-time "punctual" promise icon (icon_punctual PNG)
                  Image.asset(
                    KeetaAssets.iconPunctual,
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      KeetaIcons.deliveryTime,
                      size: 20,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'checkout.ontime_title'.tr(),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: AppTextStyles.medium,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'checkout.ontime_sub'.tr(),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    KeetaIcons.arrowRight,
                    size: 16,
                    color: AppColors.tertiaryText,
                  ),
                ],
              ),
            ),
          ),
          const ThinDivider(indent: AppSpacing.s16),
          // Rider tip row — chip strip
          TipRow(selected: tip, options: options, onSelect: onTipSelect),
        ],
      ),
    );
  }
}
