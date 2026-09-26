import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/jameia_image.dart';
import 'search_highlighted_text.dart';
import 'search_suggestion_price.dart';

/// One live product match: a 48 dp rounded thumbnail, the name with the
/// typed part in bold and the price under it. Opens the product page (where a
/// variant product's options are chosen). Read as one element.
class SearchSuggestionTile extends StatelessWidget {
  const SearchSuggestionTile({
    super.key,
    required this.product,
    required this.query,
    required this.pro,
    required this.onTap,
  });

  static const double _thumb = AppSize.s48;

  final CatalogProductEntity product;
  final String query;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.s64),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                children: [
                  JameiaImage(
                    url: product.image,
                    width: _thumb,
                    height: _thumb,
                    radius: AppRadius.card,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SearchHighlightedText(text: product.name, query: query),
                        const SizedBox(height: AppSpacing.s2),
                        SearchSuggestionPrice(product: product, pro: pro),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
