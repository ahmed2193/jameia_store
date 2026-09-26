import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_layout.dart';
import 'home_section_header.dart';

/// The band a titled home block sits in: its header (backend title + icon +
/// the arrow to the collection) over [child], edge to edge.
///
/// A plain block is white and runs straight on from the page; a themed one
/// ([fill] other than white) is a tinted band with its own breathing room,
/// the way the storefront sets its campaigns apart.
class HomeSectionBlock extends StatelessWidget {
  const HomeSectionBlock({
    super.key,
    required this.section,
    required this.child,
    this.onSeeAll,
    this.fill = AppColors.white,
  });

  final HomeSectionEntity section;
  final Widget child;
  final VoidCallback? onSeeAll;

  /// Background of the band — `HomeAccentPalette.blockFill` of its theme.
  final Color fill;

  /// Whether the block is a tinted band rather than part of the white page.
  bool get isTinted => fill != AppColors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fill,
      margin: const EdgeInsetsDirectional.only(bottom: HomeLayout.blockGap),
      padding: EdgeInsetsDirectional.symmetric(
        vertical: isTinted ? AppSpacing.s16 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A block with no title still gets its header when it has somewhere
          // to go: the way to the collection must not disappear with it.
          if (section.hasTitle || onSeeAll != null)
            HomeSectionHeader(
              title: section.title,
              icon: section.icon,
              accent: section.accent,
              onSeeAll: onSeeAll,
            ),
          child,
        ],
      ),
    );
  }
}
