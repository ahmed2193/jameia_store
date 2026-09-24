import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/jameia_image.dart';

/// One cell of the "Shop by category" grid: the artwork on a soft tile with
/// the name underneath, no card chrome.
class HomeCategoryTile extends StatelessWidget {
  const HomeCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  final CatalogCategoryEntity category;
  final VoidCallback onTap;

  /// Artwork + gap + a two-line name. The grid sizes its rows by this.
  static const double height = AppSize.s110;
  static const double _artwork = AppSize.s64;
  static const double _fallbackGlyph = AppSize.s28;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // The grid gives every cell [height], so the name may take the rest.
      child: Column(
        children: [
          Container(
            width: _artwork,
            height: _artwork,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.smallBackground,
              borderRadius: BorderRadius.circular(AppSize.r14),
            ),
            child: category.hasImage
                ? JameiaImage(
                    url: category.image,
                    width: _artwork,
                    height: _artwork,
                  )
                // Three of the store's categories have no image.
                : const Icon(
                    Icons.category_rounded,
                    size: _fallbackGlyph,
                    color: AppColors.tertiaryText,
                  ),
          ),
          const SizedBox(height: AppSpacing.s6),
          // Expanded, not a fixed box: the name still fits when the customer
          // scales text up.
          Expanded(
            child: Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.primaryText,
                height: AppSize.lh1_2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
