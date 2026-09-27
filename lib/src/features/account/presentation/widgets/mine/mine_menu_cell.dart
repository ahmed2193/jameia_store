import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_icon_tile.dart';
import 'mine_tone.dart';
import 'mine_unread_badge.dart';

/// One Mine menu row (52dp): tinted icon tile, label, optional unread badge
/// and [trailing] status, and a chevron that mirrors in RTL. A frequent,
/// full-width action — it only highlights on touch (no ripple, no shrink,
/// no haptic). Paint it on a [Material] so the highlight shows.
class MineMenuCell extends StatelessWidget {
  const MineMenuCell({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = MineTone.neutral,
    this.trailing,
    this.badgeCount = 0,
  });

  static const double height = AppSize.s52;

  /// Where the label starts — dividers between rows are inset to it.
  static const double labelStart =
      AppSpacing.s16 + MineIconTile.size + AppSpacing.s12;

  static const double _chevron = AppSize.s16;

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final MineTone tone;
  final Widget? trailing;

  /// Unread-count badge next to the label; 0 hides it.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final end = trailing;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.overlayDivider,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          child: Row(
            children: [
              MineIconTile(icon: icon, tone: tone),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: AppSpacing.s8),
                MineUnreadBadge(count: badgeCount),
              ],
              if (end != null) ...[const SizedBox(width: AppSpacing.s8), end],
              const SizedBox(width: AppSpacing.s8),
              const Icon(
                HeroIcons.arrowRight,
                size: _chevron,
                color: AppColors.tertiaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
