import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_icons.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';
import 'press_row.dart';

/// One row of a list: a 24 dp leading icon, the title (+ an optional grey
/// subtitle), a trailing value / link / switch and a chevron. At least 56 dp
/// tall; it presses like every row ([PressRow]: a dip and the flat brand
/// tint). Read as one element unless [mergeSemantics] is
/// false — turn it off when [trailing] is its own control (a switch, a ✕, a
/// link) so a screen reader can still reach it.
///
/// [dense] is the flat Hero row (checkout): at least 52 dp, a 20 dp leading
/// icon 12 dp in from the edge, the text [denseGap] after it, a quiet 12 sp
/// grey sub-line and a small 16 dp grey chevron. A custom [leading] keeps its
/// own size — give it 20 dp art so the text starts at [denseTextStart].
/// [divider] draws a hairline under the row from the text start to the end
/// edge (RTL-safe), the way Hero separates stacked flat rows.
class HeroListRow extends StatelessWidget {
  const HeroListRow({
    super.key,
    required this.title,
    this.titleStyle,
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
    this.dense = false,
    this.divider = false,
    this.onTap,
  });

  static const double _disabledOpacity = 0.45;

  /// The dense row's geometry, public so a block under a dense row (a card
  /// that starts at the text column) lines up with it.
  static const double denseMinHeight = AppSize.s52;
  static const double denseInset = AppSpacing.s12;
  static const double denseLeadSize = AppSize.s20;
  static const double denseGap = AppSpacing.s12;

  /// Where a dense row's text starts, from its start edge.
  static const double denseTextStart = denseInset + denseLeadSize + denseGap;

  /// The dense row's chevron.
  static const double denseChevronSize = AppSize.s16;

  static const BoxDecoration _hairline = BoxDecoration(
    border: Border(
      bottom: BorderSide(color: AppColors.divider, width: AppSize.s1),
    ),
  );
  static const BoxDecoration _plain = BoxDecoration();

  final String title;

  /// The title's type (e.g. `itemTitleStrong` for a heading-like row); its
  /// colour is always the row's ink. Defaults to `itemTitle`.
  final TextStyle? titleStyle;
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

  /// The flat Hero variant (see the class note).
  final bool dense;

  /// A hairline under the row, from the text start to the end edge.
  final bool divider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = destructive ? AppColors.errorDeep : AppColors.primaryText;
    final lead =
        leading ??
        (icon == null
            ? null
            : HeroIcon(
                icon!,
                size: dense ? denseLeadSize : AppSize.s24,
                color: ink,
              ));
    final inset = dense ? denseInset : AppSpacing.gutter;
    final subStyle = dense
        ? AppTextStyles.bodySmall.copyWith(color: AppColors.labelGrey)
        : AppTextStyles.meta;
    const vertical = AppSpacing.s12;
    final tap = enabled ? onTap : null;
    final row = PressRow(
      onTap: tap,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: inset),
        child: Row(
          children: [
            if (lead != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: vertical),
                child: lead,
              ),
              SizedBox(width: dense ? denseGap : AppSpacing.s16),
            ],
            Expanded(
              child: DecoratedBox(
                decoration: divider ? _hairline : _plain,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: dense ? denseMinHeight : AppSize.s56,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: inset,
                      top: vertical,
                      bottom: vertical,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: (titleStyle ?? AppTextStyles.itemTitle)
                                    .copyWith(color: ink),
                              ),
                              if (subtitleWidget != null) ...[
                                const SizedBox(height: AppSpacing.s2),
                                DefaultTextStyle.merge(
                                  style: subStyle,
                                  child: subtitleWidget!,
                                ),
                              ] else if (subtitle != null &&
                                  subtitle!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  subtitle!,
                                  maxLines: subtitleMaxLines,
                                  overflow: subtitleMaxLines == null
                                      ? null
                                      : TextOverflow.ellipsis,
                                  style: subStyle,
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
                          HeroIcon(
                            HeroIcons.chevronEnd,
                            size: dense ? denseChevronSize : AppSize.s24,
                            color: dense
                                ? AppColors.secondaryText
                                : AppColors.tertiaryText,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final body = enabled ? row : Opacity(opacity: _disabledOpacity, child: row);
    return mergeSemantics ? MergeSemantics(child: body) : body;
  }
}
