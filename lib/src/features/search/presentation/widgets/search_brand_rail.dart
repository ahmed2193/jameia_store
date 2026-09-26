import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/responsive/app_size.dart';
import 'search_brand_tile.dart';

/// The brands in one horizontal row, 16 dp in from both edges. Its height
/// follows the reader's text size (a tile's name takes up to two lines).
class SearchBrandRail extends StatelessWidget {
  const SearchBrandRail({super.key, required this.brands});

  /// Line height of the tile's name ([AppTextStyles.label]: 14 / 18).
  static const double _nameLine = AppSize.s18;
  static const int _nameLines = 2;

  final List<BrandEntity> brands;

  @override
  Widget build(BuildContext context) {
    final nameHeight = MediaQuery.textScalerOf(context)
        .scale(_nameLine * _nameLines);
    return SizedBox(
      height: SearchBrandTile.size + AppSpacing.s8 + nameHeight + AppSpacing.s4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.gutter,
        ),
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
        itemBuilder: (context, index) => SearchBrandTile(
          key: ValueKey<String>(brands[index].id),
          brand: brands[index],
        ),
      ),
    );
  }
}
