import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/motion/entrance_cascade_item.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/hero_sheet_handle.dart';
import '../../../../core/widgets/state_art.dart';

/// "Welcome to Hero Pro!" — the sheet that greets a new member right after
/// the subscription goes through: the sheet handle, the Pro welcome art (the
/// bag wearing the crown, [HeroAssets.proWelcome]) settling in once, the
/// welcome copy and a button that closes the sheet, rising in after it.
class ProSuccessSheet extends StatelessWidget {
  const ProSuccessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // The sheet is scroll-controlled: it sizes to this content and may grow
    // to full height, where the copy scrolls (a small phone, large text).
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeroSheetHandle(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s24,
                AppSpacing.s16,
                AppSpacing.s24,
                AppSpacing.s20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StateArt(asset: HeroAssets.proWelcome),
                  const SizedBox(height: AppSpacing.s16),
                  EntranceCascadeItem.single(
                    index: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'pro.success_title'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'pro.success_body'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.itemTitle.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  EntranceCascadeItem.single(
                    index: 2,
                    child: AppButton(
                      label: 'pro.success_cta'.tr(),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
