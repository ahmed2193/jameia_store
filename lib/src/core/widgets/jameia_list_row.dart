import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// One row of a list: a 24 dp leading icon, the title (+ an optional grey
/// subtitle), a trailing value / link / switch and a chevron. At least 56 dp
/// tall, a highlight on press. Read as one element unless [mergeSemantics] is
/// false — turn it off when [trailing] is its own control (a switch, a ✕, a
/// link) so a screen reader can still reach it.
class JameiaListRow extends StatelessWidget {
  const JameiaListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleMaxLines,
    this.subtitleWidget,
    this.icon,
    this.leading,
    this.trailing,
    this.showChevron = true,
    this.destructive = false,
    this.enabled = true,
    this.mergeSemantics = true,
    this.onTap,
  });

  static const double _disabledOpacity = 0.45;

  final String title;
  final String? subtitle;
  final int? subtitleMaxLines;

  /// Replaces the [subtitle] text (e.g. a money run).
  final Widget? subtitleWidget;
  final IconData? icon;

  /// Replaces [icon] (a thumbnail, a badge…).
  final Widget? leading;

  /// A value, a link or a switch before the chevron.
  final Widget? trailing;
  final bool showChevron;

  /// Red title and icon (remove, delete).
  final bool destructive;
  final bool enabled;
  final bool mergeSemantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = destructive ? AppColors.errorDeep : AppColors.primaryText;
    final lead =
        leading ??
        (icon == null ? null : Icon(icon, size: AppSize.s24, color: ink));
    final tap = enabled ? onTap : null;
    final row = InkWell(
      onTap: tap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.s56),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              if (lead != null) ...[
                lead,
                const SizedBox(width: AppSpacing.s16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.itemTitle.copyWith(color: ink),
                    ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: AppSpacing.s2),
                      DefaultTextStyle.merge(
                        style: AppTextStyles.meta,
                        child: subtitleWidget!,
                      ),
                    ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: subtitleMaxLines == null
                            ? null
                            : TextOverflow.ellipsis,
                        style: AppTextStyles.meta,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.s8),
                trailing!,
              ],
              if (showChevron && tap != null) ...[
                const SizedBox(width: AppSpacing.s4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: AppSize.s24,
                  color: AppColors.tertiaryText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final body = enabled ? row : Opacity(opacity: _disabledOpacity, child: row);
    return mergeSemantics ? MergeSemantics(child: body) : body;
  }
}
