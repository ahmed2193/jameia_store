import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/phone_number.dart';

/// The flag + `+965` chip at the start of the phone unit. Kuwait only, so it
/// is a label, not a picker (no dropdown caret promising a choice).
class LoginDialCode extends StatelessWidget {
  const LoginDialCode({super.key});

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              PhoneNumber.kuwaitFlag,
              style: AppTextStyles.headingSmall.copyWith(
                fontSize: AppSize.font16,
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
            Text(
              PhoneNumber.kuwaitDialCode,
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
