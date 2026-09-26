import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'profile_bonus_hint.dart';
import 'profile_section_title.dart';

/// Title of the optional "About you" group (date of birth, gender,
/// household size) with its privacy note and the profile-bonus hint.
class ProfileAboutHeader extends StatelessWidget {
  const ProfileAboutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionTitle('profile.about_you'.tr()),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'profile.about_you_hint'.tr(),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const ProfileBonusHint(),
      ],
    );
  }
}
