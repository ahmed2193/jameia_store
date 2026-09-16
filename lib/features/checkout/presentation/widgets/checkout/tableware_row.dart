import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Cutlery row uses the real KeeTa tableware icon asset + real switch images.
/// Layout from css.json `e7aff2`: padding:14dp 0dp 20dp 12dp, flex-row.
class TablewareRow extends StatelessWidget {
  const TablewareRow({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            // Real tableware asset from order_confirm bundle
            Image.asset(
              KeetaAssets.tablewareIcon,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.restaurant_rounded,
                size: 22,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label swaps with the toggle → vertical flip on the shared
                  // [AppMotion.flip] token (gated via MotionGuard inside).
                  FlipValue(
                    flipKey: value,
                    child: Text(
                      value
                          ? 'checkout.cutlery_on'.tr()
                          : 'checkout.cutlery_off'.tr(),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'checkout.cutlery_sub'.tr(),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            // Real KeeTa switch asset (on / off)
            GestureDetector(
              onTap: () => onChanged(!value),
              child: Image.asset(
                value ? KeetaAssets.switchOn : KeetaAssets.switchOff,
                width: 48,
                height: 28,
                errorBuilder: (context, error, stackTrace) => Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
