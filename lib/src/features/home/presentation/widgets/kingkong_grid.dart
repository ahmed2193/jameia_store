import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/data/models/catalog.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Jameia "KingKong" entry grid (`home_page_header_kingkong_sub`).
///
/// Fully responsive: the column count and tile size derive from the available
/// width (4 columns on phones, up to 6 on wide screens), so tiles and 2-line
/// labels stay crisp and never overflow. Items beyond two rows page
/// horizontally with a dot indicator.
class KingKongGrid extends StatefulWidget {
  const KingKongGrid({super.key, required this.items, this.onTap});
  final List<KingKongItem> items;

  /// Tile tap → opens the category (passed its id). When null, falls back to the
  /// legacy kingkong-landing route.
  final ValueChanged<String>? onTap;

  /// Closest real Jameia iconfont glyph (used when an item has no image).
  static IconData iconFor(String name) => switch (name) {
    'restaurant' => JameiaIcons.flame,
    'shopping_basket' => JameiaIcons.cart,
    'local_pharmacy' => JameiaIcons.consultDoctor,
    'shopping_bag' => JameiaIcons.delivery,
    'set_meal' => JameiaIcons.product,
    'sell' => JameiaIcons.refund,
    'local_florist' => JameiaIcons.favorite,
    'grid_view' => JameiaIcons.more,
    _ => JameiaIcons.store,
  };

  @override
  State<KingKongGrid> createState() => _KingKongGridState();
}

class _KingKongGridState extends State<KingKongGrid> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        const labelH = 32.0; // room for a 2-line 11dp label
        final innerW = constraints.maxWidth - AppSpacing.pageMargin * 2;
        // 4 columns on phones, more on wide screens (~88dp per column).
        final cols = (innerW / 88).floor().clamp(4, 6);
        final cellW = (innerW - gap * (cols - 1)) / cols;
        final tile = cellW.clamp(44.0, 62.0);
        final cellH = tile + 4 + labelH;
        final perPage = cols * 2;
        final pageCount = (items.length / perPage).ceil();

        Widget grid(List<KingKongItem> slice) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: 8,
            mainAxisExtent: cellH,
          ),
          itemCount: slice.length,
          itemBuilder: (_, i) => StaggerEntrance(
            index: i,
            child: _KingKongCell(
              item: slice[i],
              tile: tile,
              onTap: widget.onTap,
            ),
          ),
        );

        if (pageCount <= 1) {
          return Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
              vertical: AppSpacing.s8,
            ),
            child: grid(items),
          );
        }

        final pageH = cellH * 2 + 8; // two rows + main-axis spacing
        return Column(
          children: [
            SizedBox(
              height: pageH + AppSpacing.s8 * 2,
              child: PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                itemBuilder: (_, p) {
                  final start = p * perPage;
                  final slice = items.sublist(
                    start,
                    (start + perPage).clamp(0, items.length),
                  );
                  return Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.pageMargin,
                      vertical: AppSpacing.s8,
                    ),
                    child: grid(slice),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.s4,
                bottom: AppSpacing.s8,
              ),
              child: SmoothPageIndicator(
                controller: _controller,
                count: pageCount,
                effect: const ExpandingDotsEffect(
                  dotHeight: 4,
                  dotWidth: 6,
                  expansionFactor: 2.33,
                  spacing: 2,
                  radius: 2,
                  activeDotColor: AppColors.primaryText,
                  dotColor: AppColors.dotInactive,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One launch tile: a white rounded icon tile (with a soft shadow so it reads
/// on any backdrop) + a 2-line label, → category landing.
class _KingKongCell extends StatelessWidget {
  const _KingKongCell({required this.item, required this.tile, this.onTap});
  final KingKongItem item;
  final double tile;
  final ValueChanged<String>? onTap;

  void _open(BuildContext context) {
    // Category tiles open the shop screen for that category; the kingkong id IS
    // the category id (the loader maps categories → kingkong items).
    if (onTap != null) {
      onTap!(item.id);
    } else {
      context.push(Routes.kingkongLanding, extra: item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = hexColor(item.color);
    final radius = (tile * 0.25).clamp(10.0, 16.0);
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tile,
            height: tile,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.overlayDivider,
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: item.hasImage
                ? JameiaImage(
                    url: item.image,
                    width: tile * 0.72,
                    height: tile * 0.72,
                    fit: BoxFit.cover,
                  )
                : Icon(
                    KingKongGrid.iconFor(item.icon),
                    color: color,
                    size: tile * 0.5,
                  ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              item.displayTitle,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppSize.font11,
                height: 1.1,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
