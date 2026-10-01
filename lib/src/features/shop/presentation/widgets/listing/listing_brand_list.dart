import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/brand_entity.dart';
import '../../../../../core/widgets/option_row.dart';

/// The brand filter's choices under the sheet header: "every brand", then
/// each store brand, as choice rows (radio + selection haptic). A tap pops
/// the sheet with a record, so "every brand" (`null`) is not a dismissed
/// sheet.
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
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
        itemCount: brands.length + 1,
        itemBuilder: (context, index) {
          final brand = index == 0 ? null : brands[index - 1];
          return OptionRow(
            key: ValueKey<String>(brand?.id ?? 'all'),
            title: brand?.name ?? 'shop.all_brands'.tr(),
            selected: brand?.slug == selected,
            onTap: () => context.pop((slug: brand?.slug)),
          );
        },
      ),
    );
  }
}
