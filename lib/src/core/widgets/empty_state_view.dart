import 'package:flutter/material.dart';

import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'app_button.dart';

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
              child: Icon(
                icon,
                size: AppSize.s56,
                color: AppColors.disabledText,
              ),
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
