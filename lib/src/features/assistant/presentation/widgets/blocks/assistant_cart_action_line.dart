import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_image.dart';
import '../../../domain/entities/assistant_block.dart';

/// One line of a cart proposal: thumbnail, name and "× 2". A line the
/// server sent without its product shows the quantity only. [thumbKey]
/// marks the thumbnail a confirmed proposal's flight leaves from; a [muted]
/// line (spent proposal) cross-fades its words to the muted palette.
class AssistantCartActionLine extends StatelessWidget {
  const AssistantCartActionLine({
    super.key,
    required this.item,
    this.thumbKey,
    this.muted = false,
  });

  final AssistantCartActionItem item;
  final GlobalKey? thumbKey;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final fade = MotionGuard.duration(context, AppMotion.fast);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          HeroImage(
            key: thumbKey,
            url: product?.image ?? '',
            width: AppSize.s40,
            height: AppSize.s40,
            radius: AppRadius.r4,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: fade,
              style: AppTextStyles.bodySmall.copyWith(
                color: muted ? AppColors.secondaryText : AppColors.primaryText,
              ),
              child: Text(
                product?.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          AnimatedDefaultTextStyle(
            duration: fade,
            style: AppTextStyles.bodySmall.copyWith(
              color: muted ? AppColors.labelGrey : AppColors.secondaryText,
              fontWeight: AppTextStyles.bold,
            ),
            child: Text(
              'assistant.quantity'.tr(namedArgs: {'count': '${item.quantity}'}),
            ),
          ),
        ],
      ),
    );
  }
}
