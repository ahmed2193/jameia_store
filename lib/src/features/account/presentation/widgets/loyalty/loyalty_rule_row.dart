import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// One line of the "How it works" card: the rule's icon in a small cream
/// disc (the points family's amber), then the rule.
class LoyaltyRuleRow extends StatelessWidget {
  const LoyaltyRuleRow({super.key, required this.icon, required this.text});

  static const double _disc = AppSize.s32;

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
      child: Row(
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.accent3Light,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: _disc,
                child: Icon(
                  icon,
                  size: AppSize.s18,
                  color: AppColors.accent3Dark,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
