import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_icon_view.dart';

/// One card of a "Shop by occasion" block: a square artwork tile with the
/// title and subtitle underneath it.
///
/// The backend sends no image for these cards — only an icon and an accent —
/// so the accent wash carrying the icon IS the artwork.
class HomePromoCardTile extends StatelessWidget {
  const HomePromoCardTile({super.key, required this.card, required this.onTap});

  static const double width = AppSize.s110;

  final HomePromoCard card;
  final VoidCallback onTap;

  static const double _icon = AppSize.s44;

  /// The accent deepens towards the foot of the tile, so the card reads as a
  /// piece of artwork and not as a glyph lost in a pale square.
  static const double _footAlpha = 0.22;

  /// Artwork, the gap under it, then the two caption lines.
  static const double _captionGap = AppSpacing.s6;
  static const double _captionLines = AppSize.s44;

  /// The cell height a row owes this tile at the reader's text scale.
  static double cellHeight(BuildContext context) =>
      width +
      _captionGap +
      MediaQuery.textScalerOf(context).scale(_captionLines);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width,
              height: width,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HomeAccentPalette.wash(card.accent),
                    HomeAccentPalette.strong(card.accent)
                        .withValues(alpha: _footAlpha),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: HomeIconView(
                icon: card.icon,
                size: _icon,
                color: HomeAccentPalette.strong(card.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              card.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.bold,
                height: AppSize.lh1_2,
              ),
            ),
            if (card.subtitle.isNotEmpty)
              Text(
                card.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
