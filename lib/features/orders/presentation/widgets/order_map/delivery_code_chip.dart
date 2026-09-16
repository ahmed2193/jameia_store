import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Tappable contactless delivery-code chip — copies the 4-digit handoff code to
/// the clipboard (i18n `delivery_code`). Dummy code from [KeetaOrder.deliveryCode].
class DeliveryCodeChip extends StatelessWidget {
  const DeliveryCodeChip({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('map.delivery_code'.tr())));
      },
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.s8,
          end: AppSpacing.s8,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.smallBackground,
          borderRadius: BorderRadius.circular(AppRadius.r6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'map.delivery_code'.tr(),
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: AppColors.tertiaryText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
