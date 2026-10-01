import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Why checkout is off right now ("Add KD 1.500 more to reach the minimum
/// order"), in red over the checkout bar's total.
class CartBlockReason extends StatelessWidget {
  const CartBlockReason({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeroIcon(
            HeroIcons.info,
            size: AppSize.s16,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.meta.copyWith(color: AppColors.errorDeep),
            ),
          ),
        ],
      ),
    );
  }
}
