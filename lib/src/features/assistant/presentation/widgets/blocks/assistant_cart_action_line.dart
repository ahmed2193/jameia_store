import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_image.dart';
import '../../../domain/entities/assistant_block.dart';

/// One line of a cart proposal: thumbnail, name and "× 2". A line the
/// server sent without its product shows the quantity only.
class AssistantCartActionLine extends StatelessWidget {
  const AssistantCartActionLine({super.key, required this.item});

  final AssistantCartActionItem item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          HeroImage(
            url: product?.image ?? '',
            width: AppSize.s40,
            height: AppSize.s40,
            radius: AppRadius.r4,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              product?.name ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            'assistant.quantity'.tr(namedArgs: {'count': '${item.quantity}'}),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ],
      ),
    );
  }
}
