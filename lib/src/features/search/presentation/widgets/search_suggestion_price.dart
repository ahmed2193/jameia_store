import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/utils/formatters.dart';

/// The price line of a suggestion: what the customer pays (the Pro price for
/// a member) in grey — deep green on a deal — laid out left-to-right with
/// tabular digits in every language ("KD 1.250"; read right-to-left in Arabic
/// it is "1.250 د.ك"). A product sold in variants says "choose options".
class SearchSuggestionPrice extends StatelessWidget {
  const SearchSuggestionPrice({
    super.key,
    required this.product,
    required this.pro,
  });

  final CatalogProductEntity product;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    if (!product.hasListPrice) {
      return Text(
        'catalog.choose_options'.tr(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.meta,
      );
    }
    final kd = product.priceKdFor(pro: pro);
    final deal = product.hasDiscount;
    return Semantics(
      label: Formatters.price(kd),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          '${Formatters.currency} ${Formatters.amount(kd)}',
          maxLines: 1,
          style: AppTextStyles.meta.copyWith(
            color: deal ? AppColors.brandDeep : AppColors.secondaryText,
            fontWeight: deal ? AppTextStyles.medium : AppTextStyles.regular,
            fontFeatures: AppTextStyles.tabular,
          ),
        ),
      ),
    );
  }
}
