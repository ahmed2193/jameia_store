import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/skeletonized.dart';
import 'recipe_tile_skeleton.dart';

/// What the recipe list shows on a first load with nothing saved: a column
/// of [RecipeTileSkeleton]s in the list's own padding. Rows past a short
/// screen are clipped, never scrolled.
class RecipesSkeleton extends StatelessWidget {
  const RecipesSkeleton({super.key});

  static const int _rows = 6;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
      child: Skeletonized(
        loading: true,
        child: Column(
          children: [
            for (var i = 0; i < _rows; i++) const RecipeTileSkeleton(),
          ],
        ),
      ),
    );
  }
}
