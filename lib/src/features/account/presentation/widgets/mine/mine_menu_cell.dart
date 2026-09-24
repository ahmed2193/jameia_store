import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_unread_badge.dart';

/// One Mine menu row (bundle `c4e0db`: 48dp tall, 12dp side padding): icon,
/// label, optional unread badge / trailing widget, arrow.
class MineMenuCell extends StatelessWidget {
  const MineMenuCell({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Unread-count badge next to the label; 0 hides it.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final end = trailing;
    // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
    // whole cell gives the subtle press feel.
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox(
          height: AppSize.s48,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
            ),
            child: Row(
              children: [
                Icon(icon, size: AppSize.s20, color: AppColors.primaryText),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                if (badgeCount > 0) ...[
                  MineUnreadBadge(count: badgeCount),
                  const SizedBox(width: AppSpacing.s8),
                ],
                if (end != null) ...[end, const SizedBox(width: AppSpacing.s8)],
                Image.asset(
                  JameiaAssets.mineArrowCell,
                  width: AppSize.s18,
                  height: AppSize.s18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
