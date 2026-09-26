import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/category_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/motion/press_scale.dart';
import 'search_tile_image.dart';

/// A category of the search screen: its photo on a flat 16 dp tile and the
/// name under it (two lines at most). Opens the category.
class SearchCategoryTile extends StatelessWidget {
  const SearchCategoryTile({super.key, required this.category});

  static const double _pressedScale = 0.97;

  final CatalogCategoryEntity category;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: category.name,
      excludeSemantics: true,
      child: PressScale(
        pressedScale: _pressedScale,
        onTap: () =>
            context.push(Routes.category, extra: CategoryArgs.of(category)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: SearchTileImage(
                url: category.image,
                initial: category.initial,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label,
            ),
          ],
        ),
      ),
    );
  }
}
