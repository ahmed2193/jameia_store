import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'about_social.dart';
import 'about_social_chip.dart';

/// "Follow us": a heading, how the tiles work, and one tile per profile.
class AboutFollowSection extends StatelessWidget {
  const AboutFollowSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s4,
          ),
          child: Semantics(
            header: true,
            child: Text(
              'account.follow_us'.tr(),
              style: AppTextStyles.subheadingMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s4,
          ),
          child: Text(
            'settings.follow_us_hint'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Row(
          children: [
            for (final social in AboutSocial.values) ...[
              if (social.index > 0) const SizedBox(width: AppSpacing.s12),
              Expanded(child: AboutSocialChip(social: social)),
            ],
          ],
        ),
      ],
    );
  }
}
