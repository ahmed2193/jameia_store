import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../../core/responsive/app_size.dart';

/// A coupon code to copy: label, the code in a tinted pill and a copy icon.
/// The code is read as one unit, left to right, in both languages.
class AssistantCouponChip extends StatelessWidget {
  const AssistantCouponChip({super.key, required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    Haptics.selection();
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    showJameiaSnackBar(context, 'assistant.coupon_copied'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'assistant.coupon_copy'.tr(namedArgs: {'code': code}),
      excludeSemantics: true,
      onTap: () => _copy(context),
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSize.s48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.promotionTagLightBg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.promotionTagFgOnLight),
          ),
          child: Row(
            children: [
              Text(
                'assistant.coupon_label'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.promotionTagFgOnLight,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.copy_rounded,
                size: AppSize.s18,
                color: AppColors.promotionTagFgOnLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
