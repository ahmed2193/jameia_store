import 'package:flutter/material.dart';

import '../../../../core/motion/motion_widgets.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/shop_entity.dart';

/// Jameia "Popular brands 🔥" grid — a horizontally-scrolling strip of brand
/// logo tiles laid out in TWO rows (columns of 2). Each tile is a white
/// rounded-square with a 0.5dp `#f0f0f0` hairline and the shop's logo filling
/// it (bundle class `bcd560`, r16). Tile size scales a touch on wide screens.
class PopularBrandsGrid extends StatelessWidget {
  const PopularBrandsGrid({
    super.key,
    required this.brands,
    required this.onOpen,
  });

  final List<ShopEntity> brands;
  final void Function(String shopId) onOpen;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();
    // Responsive tile: ~64dp on phones, a little larger on tablets.
    final w = MediaQuery.sizeOf(context).width;
    final tile = (w * 0.17).clamp(60.0, 84.0).toDouble();
    const gap = AppSpacing.s10;
    final columns = (brands.length / 2).ceil();

    return SizedBox(
      height: tile * 2 + gap,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
        ),
        itemCount: columns,
        separatorBuilder: (_, _) => const SizedBox(width: gap),
        itemBuilder: (_, col) {
          final top = brands[col * 2];
          final bottomIndex = col * 2 + 1;
          final bottom = bottomIndex < brands.length
              ? brands[bottomIndex]
              : null;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandTile(shop: top, size: tile, onTap: () => onOpen(top.id)),
              SizedBox(height: gap),
              if (bottom != null)
                _BrandTile(
                  shop: bottom,
                  size: tile,
                  onTap: () => onOpen(bottom.id),
                )
              else
                SizedBox(width: tile, height: tile),
            ],
          );
        },
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({
    required this.shop,
    required this.size,
    required this.onTap,
  });

  final ShopEntity shop;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r3), // 16dp
          border: Border.all(color: AppColors.brandTileBorder, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: JameiaImage(
          url: shop.logo,
          width: size - 12,
          height: size - 12,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
