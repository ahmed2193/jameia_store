import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/widgets/shelf_pro_price_chip.dart';
import '../../../../core/widgets/shelf_save_badge.dart';
import 'pdp_info_chip.dart';
import 'pdp_stock_note.dart';

/// The compact notes under the description: the lime "Save N%" of a deal,
/// "Pro price" when a member pays less, how the stock stands when it
/// matters ("Only 3 left", out of stock) and, for a customer who is not a
/// member, the violet Pro price chip. All values arrive decided by the
/// domain. Takes no room when there is nothing to note.
class PdpInfoNotes extends StatelessWidget {
  const PdpInfoNotes({
    super.key,
    required this.inStock,
    this.lowStockLeft,
    this.discountPercent = 0,
    this.proPriceApplied = false,
    this.proPriceHintFils,
  });

  final bool inStock;
  final int? lowStockLeft;

  /// Whole percent off the struck price; `0` = no badge.
  final int discountPercent;

  /// A Pro member pays less than the regular price.
  final bool proPriceApplied;

  /// What a Pro member would pay, shown to a customer who is not one.
  final int? proPriceHintFils;

  @override
  Widget build(BuildContext context) {
    final hint = proPriceHintFils;
    final stock = PdpStockNote.shows(
      inStock: inStock,
      lowStockLeft: lowStockLeft,
    );
    if (discountPercent <= 0 && !proPriceApplied && !stock && hint == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
      child: Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (discountPercent > 0) ShelfSaveBadge(percent: discountPercent),
          if (proPriceApplied)
            PdpInfoChip(
              label: 'product.pro_price_applied'.tr(),
              foreground: AppColors.accentViolet,
              background: AppColors.accentVioletLight,
            ),
          if (stock) PdpStockNote(inStock: inStock, lowStockLeft: lowStockLeft),
          if (hint != null)
            ShelfProPriceChip(
              priceKd: hint / CatalogProductEntity.filsPerDinar,
            ),
        ],
      ),
    );
  }
}
