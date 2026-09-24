import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import 'pdp_section_card.dart';
import 'pdp_variant_chip.dart';

/// The options of a variant product. Exactly one is selected (the first one
/// that can be bought, until the customer picks another).
class PdpVariantSelector extends StatelessWidget {
  const PdpVariantSelector({
    super.key,
    required this.variants,
    required this.selectedId,
    required this.pro,
    required this.onSelect,
  });

  final List<CatalogVariantEntity> variants;
  final String? selectedId;
  final bool pro;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return PdpSectionCard(
      title: 'product.choose_size'.tr(),
      child: Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: [
          for (final variant in variants)
            PdpVariantChip(
              key: ValueKey(variant.id),
              variant: variant,
              selected: variant.id == selectedId,
              pro: pro,
              onTap: () => onSelect(variant.id),
            ),
        ],
      ),
    );
  }
}
