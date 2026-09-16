import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../motion/motion_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';
import 'branded_loader.dart';

/// Branded KeeTa loader (brand-yellow dot pulse). Was a bare
/// [CircularProgressIndicator]; now routes through [BrandedLoader] so every
/// loading spot in the app shares the brand look. Inline-sized loaders use the
/// cheap painted dots; pass a larger [size] for block loads.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 28});
  final double size;
  @override
  Widget build(BuildContext context) => Center(
    child: BrandedLoader.inline(size: size * 1.6, color: AppColors.primary),
  );
}

/// Empty-state placeholder.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopScale.onMount(
              child: Icon(icon, size: 56, color: AppColors.disabledText),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.s16),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error-state placeholder with retry.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PopScale.onMount(
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
            ),
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
