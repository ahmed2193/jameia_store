import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import '../../../../core/responsive/app_size.dart';
import 'pdp_section.dart';
import 'pdp_size_card.dart';

/// The options of a variant product under a bold title, as talabat size
/// cards two to a row on a phone (more on a wide screen). Exactly one is
/// selected (the first one that can be bought, until the customer picks
/// another).
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

  static const double _gap = AppSpacing.s12;
  static const double _maxCardWidth = AppSize.s220;
  static const int _minColumns = 2;

  /// Width of one card in a row [maxWidth] wide: at least two to a row,
  /// floored so a full row never wraps on a rounding error.
  static double cardWidthFor(double maxWidth) {
    final columns = math.max(
      _minColumns,
      ((maxWidth + _gap) / (_maxCardWidth + _gap)).floor(),
    );
    return ((maxWidth - _gap * (columns - 1)) / columns).floorToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Any card with a third line (a struck price, "out of stock") makes the
    // others keep its room, so every card of a row lines up.
    final reservesThirdLine = variants.any(
      (variant) => !variant.isAvailable || variant.compareAtFilsAt(now) != null,
    );
    return PdpSection(
      title: 'product.choose_size'.tr(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = cardWidthFor(constraints.maxWidth);
          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final variant in variants)
                PdpSizeCard(
                  key: ValueKey(variant.id),
                  variant: variant,
                  selected: variant.id == selectedId,
                  pro: pro,
                  width: width,
                  compareAtFils: variant.compareAtFilsAt(now),
                  reservesThirdLine: reservesThirdLine,
                  onTap: () => onSelect(variant.id),
                ),
            ],
          );
        },
      ),
    );
  }
}
