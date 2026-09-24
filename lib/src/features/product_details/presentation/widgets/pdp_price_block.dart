import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/catalog_discount_badge.dart';
import '../../../../core/widgets/catalog_save_badge.dart';
import 'pdp_info_chip.dart';
import 'pdp_section_card.dart';

/// Price of what is selected: the amount the customer pays, the struck "was"
/// price with its discount, and the Pro price — charged to a Pro member, shown
/// as a hint to everybody else. All amounts arrive in fils, already decided by
/// the domain ([ProductDetail]).
class PdpPriceBlock extends StatelessWidget {
  const PdpPriceBlock({
    super.key,
    required this.priceFils,
    this.compareAtFils,
    this.discountPercent = 0,
    this.regularPriceFilsWhenPro,
    this.proPriceFilsHint,
  });

  final int priceFils;

  /// Valid struck price, or `null`.
  final int? compareAtFils;

  /// Whole percent off [compareAtFils]; `0` = no badge.
  final int discountPercent;

  /// Set when a Pro member pays less than this regular price.
  final int? regularPriceFilsWhenPro;

  /// Set for a non-member when the product has a Pro price.
  final int? proPriceFilsHint;

  static double _kd(int fils) => fils / CatalogProductEntity.filsPerDinar;

  @override
  Widget build(BuildContext context) {
    final struck = compareAtFils ?? regularPriceFilsWhenPro;
    final proHint = proPriceFilsHint;
    final compareAt = compareAtFils;
    return PdpSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s4,
            children: [
              Text(
                Formatters.price(_kd(priceFils)),
                style: AppTextStyles.displaySmall.copyWith(
                  color: struck != null
                      ? AppColors.finalPrice
                      : AppColors.primaryText,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              if (struck != null)
                Text(
                  Formatters.price(_kd(struck)),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.tertiaryText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              if (discountPercent > 0)
                CatalogDiscountBadge(percent: discountPercent),
              if (regularPriceFilsWhenPro != null)
                PdpInfoChip(
                  label: 'product.pro_price_applied'.tr(),
                  foreground: AppColors.accent4Foreground,
                  background: AppColors.accent4Light,
                ),
            ],
          ),
          if (compareAt != null && compareAt > priceFils) ...[
            const SizedBox(height: AppSpacing.s6),
            CatalogSaveBadge(amountKd: _kd(compareAt - priceFils)),
          ],
          if (proHint != null) ...[
            const SizedBox(height: AppSpacing.s6),
            Text(
              'product.pro_price_hint'.tr(
                namedArgs: {'price': Formatters.price(_kd(proHint))},
              ),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.accent4Foreground,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
