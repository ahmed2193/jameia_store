import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_section_header.dart';

/// The card a titled home block sits in: its header (backend title + icon +
/// "view all") over [child].
///
/// Two shapes, both driven by the block's own data: a plain block is a
/// full-bleed white band, a themed one ([inset]) is a tinted rounded card
/// floating on the page. Alternating them is what gives the feed its rhythm.
class HomeSectionBlock extends StatelessWidget {
  const HomeSectionBlock({
    super.key,
    required this.section,
    required this.child,
    this.onSeeAll,
    this.fill = AppColors.white,
    this.inset = false,
    this.leading,
  });

  final HomeSectionEntity section;
  final Widget child;
  final VoidCallback? onSeeAll;

  /// Background of the block — `HomeAccentPalette.blockFill` of its theme.
  final Color fill;

  /// Whether the block is a rounded card inset from the page edges instead of
  /// a full-bleed band.
  final bool inset;

  /// Sits above the header — the promo card at the head of a themed block.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    // A block with no title still gets its header when it has somewhere to go:
    // "view all" must not disappear with the heading.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?leading,
        if (section.hasTitle || onSeeAll != null)
          HomeSectionHeader(
            title: section.title,
            icon: section.icon,
            accent: section.accent,
            onSeeAll: onSeeAll,
            fill: fill,
          ),
        child,
      ],
    );
    if (!inset) {
      return Container(
        color: fill,
        margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s10,
        ),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.s8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s10,
          ),
          child: content,
        ),
      ),
    );
  }
}
