import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/responsive/app_size.dart';
import 'search_category_tile.dart';

/// The categories in rows of equal tiles: as many columns as fit a tile of
/// at least [_minTileWidth] (grown with the reader's text size, so a name
/// never breaks mid-word), between [_minColumns] and [_maxColumns]. A row is
/// as tall as its tallest name.
class SearchCategoryGrid extends StatelessWidget {
  const SearchCategoryGrid({super.key, required this.categories});

  static const double _minTileWidth = AppSize.s80;
  static const int _minColumns = 3;
  static const int _maxColumns = 6;
  static const double _gap = AppSpacing.s12;

  final List<CatalogCategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    final minTile = MediaQuery.textScalerOf(context).scale(_minTileWidth);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + _gap) / (minTile + _gap))
            .floor()
            .clamp(_minColumns, _maxColumns);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < categories.length; row += columns) ...[
              if (row > 0) const SizedBox(height: AppSpacing.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = row; i < row + columns; i++) ...[
                    if (i > row) const SizedBox(width: _gap),
                    Expanded(
                      child: i < categories.length
                          ? SearchCategoryTile(
                              key: ValueKey<String>(categories[i].id),
                              category: categories[i],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
