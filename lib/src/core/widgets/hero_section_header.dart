import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'hero_text_link.dart';

/// Section heading: a bold title and, at the end, either [trailing] or an
/// underlined "View all" link (or [seeAllLabel], e.g. "Clear").
class HeroSectionHeader extends StatelessWidget {
  const HeroSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel,
    this.trailing,
    this.titleStyle,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.gutter,
      AppSpacing.section,
      AppSpacing.gutter,
      AppSpacing.s8,
    ),
  });

  final String title;
  final VoidCallback? onSeeAll;

  /// Defaults to `catalog.view_all`.
  final String? seeAllLabel;

  /// Replaces the see-all link (e.g. a link that stays visible but disabled).
  final Widget? trailing;

  /// Defaults to [AppTextStyles.sectionTitle].
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final end =
        trailing ??
        (onSeeAll == null
            ? null
            : HeroTextLink(
                label: seeAllLabel ?? 'catalog.view_all'.tr(),
                onTap: onSeeAll,
              ));
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: titleStyle ?? AppTextStyles.sectionTitle,
              ),
            ),
          ),
          ?end,
        ],
      ),
    );
  }
}
