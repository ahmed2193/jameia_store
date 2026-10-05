import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon_plate.dart';

/// One "how it works" line of the first-order dialog: the [icon] on its
/// plate, a bold [title] and the grey [body] under it.
class HomeFirstOrderStep extends StatelessWidget {
  const HomeFirstOrderStep({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  static const double _plate = AppSize.s36;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroIconPlate(icon, size: _plate),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(body, style: AppTextStyles.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
