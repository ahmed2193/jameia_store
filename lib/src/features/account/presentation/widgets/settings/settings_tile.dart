import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/press_row.dart';
import 'settings_icon_badge.dart';
import 'settings_tone.dart';

/// One settings row: tinted icon badge, title (+ optional subtitle), an
/// optional full-width control [below] them, and a trailing control — or,
/// for a row that opens something, a chevron that mirrors under RTL. A row
/// with [onTap] presses like every row in the app ([PressRow]: a dip and the
/// flat brand tint); a row without one stays still.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    this.subtitle,
    this.below,
    this.trailing,
    this.onTap,
    this.chevron = true,
    this.titleColor = AppColors.primaryText,
  });

  static const double _minHeight = AppSize.s56;

  final IconData icon;
  final SettingsTone tone;
  final String title;
  final String? subtitle;

  /// A control under the title that takes the row's full text width (one
  /// too wide to share the line with the title at large text sizes).
  final Widget? below;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Shows the chevron when the row has an [onTap] and no [trailing].
  final bool chevron;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final end = trailing;
    final detail = subtitle;
    final control = below;
    return PressRow(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s10,
          ),
          child: Row(
            // A row with a control below keeps the badge beside the title.
            crossAxisAlignment: control == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              SettingsIconBadge(icon: icon, tone: tone),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: titleColor,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        detail,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (control != null) ...[
                      const SizedBox(height: AppSpacing.s10),
                      control,
                    ],
                  ],
                ),
              ),
              if (end != null) ...[
                const SizedBox(width: AppSpacing.s12),
                end,
              ] else if (chevron && onTap != null) ...[
                const SizedBox(width: AppSpacing.s8),
                const HeroIcon(
                  HeroIcons.chevronEnd,
                  size: AppSize.s16,
                  color: AppColors.tertiaryText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
