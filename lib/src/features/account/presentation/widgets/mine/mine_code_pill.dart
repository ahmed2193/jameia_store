import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// The dark pill showing the delivery [code] on the Mine tab: tabular digits
/// laid out left-to-right in both languages; a dashed placeholder while no
/// code is set.
class MineCodePill extends StatelessWidget {
  const MineCodePill({super.key, required this.code});

  static const String _noCode = '— — — —';

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSize.s28,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryText,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          code.isEmpty ? _noCode : code,
          maxLines: 1,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.white,
            letterSpacing: AppSize.s1_5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
