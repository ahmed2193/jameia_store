import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_loader.dart';

/// Tail of a paginated grid: a loader while the next page is coming, a retry
/// row when it failed, nothing otherwise.
class ListingLoadMoreFooter extends StatelessWidget {
  const ListingLoadMoreFooter({
    super.key,
    required this.isLoading,
    required this.hasFailed,
    required this.onRetry,
  });

  final bool isLoading;
  final bool hasFailed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (hasFailed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.link),
            label: Text(
              'retry'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.link),
            ),
          ),
        ),
      );
    }
    if (!isLoading) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s16),
      child: Center(child: AppLoader()),
    );
  }
}
