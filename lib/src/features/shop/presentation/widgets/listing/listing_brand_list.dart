import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/brand_entity.dart';
import 'listing_brand_row.dart';

/// The brand filter's choices: "every brand", then each store brand. A tap
/// pops the sheet with a record, so "every brand" (`null`) is not a
/// dismissed sheet.
class ListingBrandList extends StatelessWidget {
  const ListingBrandList({
    super.key,
    required this.brands,
    required this.selected,
  });

  final List<BrandEntity> brands;

  /// The brand slug the list is filtered by, `null` for all of them.
  final String? selected;

  static const double _maxHeightFactor = 0.6;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Text(
              'shop.brand'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
              itemCount: brands.length + 1,
              itemBuilder: (context, index) {
                final brand = index == 0 ? null : brands[index - 1];
                return ListingBrandRow(
                  key: ValueKey<String>(brand?.id ?? 'all'),
                  label: brand?.name ?? 'shop.all_brands'.tr(),
                  isSelected: brand?.slug == selected,
                  onTap: () => context.pop((slug: brand?.slug)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
