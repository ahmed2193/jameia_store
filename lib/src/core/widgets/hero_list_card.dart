import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';
import 'hero_surface_card.dart';

/// Rows grouped on one white hairline card, a hairline between neighbours
/// that starts past the rows' 24 dp leading icon (RTL-safe). Pass only the
/// rows that show — a row that renders nothing would still get a hairline.
class HeroListCard extends StatelessWidget {
  const HeroListCard({
    super.key,
    required this.children,
    this.dividerIndent = AppSpacing.gutter + AppSize.s24 + AppSpacing.s16,
  });

  final List<Widget> children;

  /// Where each hairline starts.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return HeroSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppSize.s1,
                thickness: AppSize.s1,
                color: AppColors.divider,
                indent: dividerIndent,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
