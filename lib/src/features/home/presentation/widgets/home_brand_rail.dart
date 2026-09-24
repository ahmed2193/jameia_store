import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_brand_chip.dart';
import 'home_section_block.dart';

/// "Shop by brand": a lazily built horizontal strip of round brand logos.
class HomeBrandRail extends StatelessWidget {
  const HomeBrandRail({
    super.key,
    required this.section,
    required this.onOpenBrand,
    required this.onViewAll,
  });

  final HomeBrandRailSection section;
  final ValueChanged<BrandEntity> onOpenBrand;
  final VoidCallback onViewAll;

  static const double _height = AppSize.s92;

  @override
  Widget build(BuildContext context) {
    final brands = section.brands;
    return HomeSectionBlock(
      section: section,
      onSeeAll: onViewAll,
      child: SizedBox(
        height: _height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageMargin,
          ),
          itemCount: brands.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (context, index) => HomeBrandChip(
            key: ValueKey(brands[index].id),
            brand: brands[index],
            onTap: () => onOpenBrand(brands[index]),
          ),
        ),
      ),
    );
  }
}
