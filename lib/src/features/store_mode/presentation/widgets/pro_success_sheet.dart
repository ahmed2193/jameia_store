import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/app_button.dart';

/// "Welcome to Jm3eia Pro!" — the sheet that greets a new member right after
/// the subscription goes through: a crown in a Pro-gradient disc that pops
/// in, the welcome copy, and a button that closes the sheet.
class ProSuccessSheet extends StatelessWidget {
  const ProSuccessSheet({super.key});

  static const double _disc = AppSize.s88;
  static const double _halo = AppSize.s140;
  static const double _crown = AppSize.s44;
  static const double _haloAlpha = 0.18;
  static const double _buttonHeight = AppSize.s52;

  static const BoxDecoration _discDecoration = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: AppColors.proGradient,
    ),
    boxShadow: AppShadows.high,
  );

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
            SizedBox.square(
              dimension: _halo,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentViolet.withValues(alpha: _haloAlpha),
                      AppColors.accentViolet.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Center(
                  child: PopScale.onMount(
                    duration: AppMotion.slow,
                    curve: AppMotion.emphasized,
                    child: const SizedBox.square(
                      dimension: _disc,
                      child: DecoratedBox(
                        decoration: _discDecoration,
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: _crown,
                          color: AppColors.proAmber,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
