import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Soft green pill with the app version.
class AboutVersionChip extends StatelessWidget {
  const AboutVersionChip({super.key});

  /// The release shown on About; keep in step with `version:` in
  /// pubspec.yaml (the app ships no package-info plugin).
  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandLightBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          'account.version'.tr(namedArgs: {'version': appVersion}),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
