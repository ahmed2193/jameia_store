import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../design/hero_assets.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'app_outline_button.dart';
import 'state_art.dart';

/// Error-state placeholder with retry: the error illustration
/// ([HeroAssets.stateError]), the message and a Retry pill.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StateArt(asset: HeroAssets.stateError),
            const SizedBox(height: AppSpacing.s12),
            Text(
              message ?? 'core.something_went_wrong'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppOutlineButton(label: 'retry'.tr(), onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
