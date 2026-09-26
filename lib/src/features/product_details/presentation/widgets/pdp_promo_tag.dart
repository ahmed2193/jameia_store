import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/sticker_text.dart';

/// The deal over the buy bar's price: the name of the cart offer that
/// counts this product ("2 KWD off dairy (3 items)", as the backend words
/// it) in white sticker letters on a red tag. It pops in when it arrives.
class PdpPromoTag extends StatelessWidget {
  const PdpPromoTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PopScale.onMount(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent1,
          borderRadius: BorderRadius.circular(AppRadius.r6),
        ),
        child: StickerText(
          label,
          rim: AppSize.s2,
          style: AppTextStyles.tag.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
