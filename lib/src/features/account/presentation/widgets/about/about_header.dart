import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import 'about_logo.dart';
import 'about_version_chip.dart';

/// Top of About: the app icon pops in once, then the name and the version.
class AboutHeader extends StatelessWidget {
  const AboutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const RepaintBoundary(child: PopScale.onMount(child: AboutLogo())),
        const SizedBox(height: AppSpacing.s16),
        Text(
          'account.app_name'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.displayMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        const AboutVersionChip(),
      ],
    );
  }
}
