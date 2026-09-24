import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/jameia_image.dart';

/// A brand of the "Shop by brand" rail: round logo (or the brand's initial when
/// it has no logo) over its name.
class HomeBrandChip extends StatelessWidget {
  const HomeBrandChip({super.key, required this.brand, required this.onTap});

  static const double width = AppSize.s72;
  static const double _logo = AppSize.s64;

  final BrandEntity brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              width: _logo,
              height: _logo,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.smallBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandTileBorder),
              ),
              child: brand.hasImage
                  ? JameiaImage.circle(url: brand.image, size: _logo)
                  : Text(
                      brand.initial,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              brand.name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
