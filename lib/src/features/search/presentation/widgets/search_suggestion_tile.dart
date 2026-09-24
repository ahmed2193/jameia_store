import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/jameia_image.dart';
import 'search_highlighted_text.dart';

/// One live suggestion: the product's thumbnail, its name with the match
/// highlighted, and its price (or "choose options" for a variant product).
class SearchSuggestionTile extends StatelessWidget {
  const SearchSuggestionTile({
    super.key,
    required this.product,
    required this.query,
    required this.pro,
    required this.onTap,
  });

  final CatalogProductEntity product;
  final String query;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        child: Row(
          children: [
            JameiaImage(
              url: product.image,
              width: AppSize.s44,
              height: AppSize.s44,
              radius: AppSize.r8,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: SearchHighlightedText(text: product.name, query: query),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              product.hasListPrice
                  ? Formatters.price(product.priceKdFor(pro: pro))
                  : 'catalog.choose_options'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
