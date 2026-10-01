import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../../../core/widgets/option_row.dart';
import 'listing_sort_label.dart';

/// Bottom sheet listing the product orderings: the shared sheet header, then
/// one choice row per ordering (the radio and the selection haptic every
/// choice sheet has), cascading in under the header. Pops with a record so
/// "the backend's default" (`null`) is distinguishable from a dismissed
/// sheet.
class ListingSortSheet extends StatelessWidget {
  const ListingSortSheet({super.key, required this.selected});

  final CatalogProductSort? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroSheetHeader(title: 'shop.sort_by'.tr()),
          for (final (index, option) in ListingSortLabel.options.indexed)
            EntranceCascadeItem.single(
              index: index + 1,
              child: OptionRow(
                title: ListingSortLabel.keyOf(option).tr(),
                selected: option == selected,
                onTap: () => context.pop((sort: option)),
              ),
            ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }
}
