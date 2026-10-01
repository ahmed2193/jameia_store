import 'package:flutter/material.dart';

import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_icons.dart';
import './hero_icon.dart';
import 'app_button.dart';
import 'state_art.dart';

/// Empty-state placeholder: the screen's illustration ([art], a `HeroAssets`
/// state / empty plate drawn by [StateArt]; or a composed [illustration],
/// e.g. the assistant with a prop) — or, for a screen that has none, a
/// muted [icon] — then the message and an optional action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = HeroIcons.inbox,
    this.art,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  final String message;

  /// The glyph when there is no [art].
  final IconData icon;
  final String? art;

  /// Drawn in place of [art] / [icon] when given.
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final asset = art;
    final drawn = illustration;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (drawn != null)
              drawn
            else if (asset != null)
              StateArt(asset: asset)
            else
              PopScale.onMount(
                child: HeroIcon(
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
