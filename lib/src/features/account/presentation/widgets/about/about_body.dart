import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import 'about_follow_section.dart';
import 'about_header.dart';
import 'about_links_section.dart';

/// About: the app header, the legal / feedback rows, the social profiles and
/// the copyright line. The groups rise in once ([EntranceCascade]) — not
/// under the page's own push, which is the entrance then.
class AboutBody extends StatelessWidget {
  const AboutBody({super.key});

  @override
  Widget build(BuildContext context) {
    return EntranceCascade(
      child: ContentClamp(
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            MediaQuery.paddingOf(context).bottom + AppSpacing.s32,
          ),
          children: [
            const AboutHeader(),
            const SizedBox(height: AppSpacing.s32),
            const EntranceCascadeItem(index: 0, child: AboutLinksSection()),
            const SizedBox(height: AppSpacing.s24),
            const EntranceCascadeItem(index: 1, child: AboutFollowSection()),
            const SizedBox(height: AppSpacing.s32),
            EntranceCascadeItem(
              index: 2,
              child: Text(
                'account.copyright'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
