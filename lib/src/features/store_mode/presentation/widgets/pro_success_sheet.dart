import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_art.dart';

/// "Welcome to Hero Pro!" — the sheet that greets a new member right after
/// the subscription goes through: the Pro welcome art (the bag wearing the
/// crown, [HeroAssets.proWelcome]) fading in once, the welcome copy, and a
/// button that closes the sheet.
class ProSuccessSheet extends StatelessWidget {
  const ProSuccessSheet({super.key});

  static const double _buttonHeight = AppSize.s52;

  @override
  Widget build(BuildContext context) {
    // The sheet is scroll-controlled: it sizes to this content and may grow
    // to full height, where the copy scrolls (a small phone, large text).
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s24,
          AppSpacing.s24,
          AppSpacing.s24,
          AppSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StateArt(asset: HeroAssets.proWelcome),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'pro.success_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge.copyWith(
                fontSize: AppSize.font24,
                fontWeight: AppTextStyles.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'pro.success_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              label: 'pro.success_cta'.tr(),
              height: _buttonHeight,
              radius: AppRadius.pill,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
