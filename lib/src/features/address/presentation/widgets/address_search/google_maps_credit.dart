import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "Google Maps" under answers that came from Google, on a screen that
/// shows no Google map (Google's attribution rule for Places results).
class GoogleMapsCredit extends StatelessWidget {
  const GoogleMapsCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.s12,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          'addr.search.google_credit'.tr(),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
