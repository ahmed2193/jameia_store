import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/sticker_text.dart';

/// The red deal tag of the checkout ("Add KD 1.500 for free delivery",
/// "20% off"): white sticker letters on `couponBadgeRed`, one line, 16 dp
/// tall at 1× text (the tag style's line), 4 dp corners.
class CheckoutRedTag extends StatelessWidget {
  const CheckoutRedTag({super.key, required this.label});

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppSize.r4),
  );

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.couponBadgeRed,
        borderRadius: _radius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s6,
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
