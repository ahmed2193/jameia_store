import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/widgets/jameia_section_header.dart';
import 'search_brand_rail.dart';

/// "Brands": the store's brands as one row of logo tiles, with "View all"
/// opening the brands page (the row scrolls past the screen edge).
class SearchBrandsSection extends StatelessWidget {
  const SearchBrandsSection({super.key, required this.brands});

  final List<BrandEntity> brands;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        JameiaSectionHeader(
          title: 'search.brands'.tr(),
          onSeeAll: () => context.push(Routes.brands),
        ),
        SearchBrandRail(brands: brands),
      ],
    );
  }
}
