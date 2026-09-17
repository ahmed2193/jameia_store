import 'package:flutter/material.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/core_widgets.dart';
import 'home_section_header.dart';

/// Jameia home tiles area (`home_page_header_tiles_area`): a title row + a
/// horizontal strip of rectangular category tiles (r5, 10dp gap).
class TilesArea extends StatelessWidget {
  const TilesArea({
    super.key,
    required this.title,
    required this.tiles,
    required this.onOpen,
  });

  final String title;
  final List<HomeTile> tiles;
  final void Function(HomeTile tile) onOpen;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: title),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            itemCount: tiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _TileView(tile: tiles[i], onTap: () => onOpen(tiles[i])),
          ),
        ),
      ],
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({required this.tile, this.onTap});
  final HomeTile tile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = hexColor(tile.bg, AppColors.brandLightBg);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 84,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tile.image.isNotEmpty)
              JameiaImage(url: tile.image, fit: BoxFit.cover),
            PositionedDirectional(
              start: 10,
              top: 10,
              end: 10,
              child: Text(
                tile.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSize.font14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tileTitleInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
