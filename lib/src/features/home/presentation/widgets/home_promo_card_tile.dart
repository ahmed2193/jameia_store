import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_category_tile.dart';
import 'home_icon_view.dart';
import 'home_layout.dart';
import 'home_loop.dart';
import 'home_tile_backdrop.dart';

/// One card of a "Shop by occasion" row, as a storefront tile: the card's
/// accent wash with its hill in the strong shade, the icon on a white disc
/// riding the crest, and the title centred underneath.
///
/// The backend sends no image for these cards — only an icon and an accent —
/// so the tile IS the artwork. Same size as the aisle tiles, so the two rows
/// read as one family. The disc floats gently while the row is on screen,
/// each tile a step behind the one before it.
class HomePromoCardTile extends StatelessWidget {
  const HomePromoCardTile({
    super.key,
    required this.card,
    required this.onTap,
    this.index = 0,
  });

  static const double width = HomeCategoryTile.width;

  final HomePromoCard card;
  final VoidCallback onTap;

  /// The tile's place in its row, so the discs float out of step.
  final int index;

  static const double _disc = AppSize.s44;
  static const double _icon = AppSize.s24;
  static const double _labelGap = AppSpacing.s6;

  /// Two lines of the title before the reader's text scale.
  static const double _labelLines = AppSize.s34;

  /// The disc straddles the crest of the hill.
  static const Alignment _discAlignment = Alignment(0, 0.15);

  /// How high the disc floats, and how far out of step two neighbours are
  /// (a share of the float).
  static const double _float = AppSpacing.s4;
  static const double _phaseStep = 0.3;

  /// The height a row owes this tile at the reader's text scale.
  static double cellHeight(BuildContext context) =>
      width + _labelGap + MediaQuery.textScalerOf(context).scale(_labelLines);

  @override
  Widget build(BuildContext context) {
    final strong = HomeAccentPalette.strong(card.accent);
    return Semantics(
      button: true,
      label: card.subtitle.isEmpty
          ? card.title
          : '${card.title}, ${card.subtitle}',
      // Replaces the child's semantics, its tap action included.
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(HomeLayout.radius),
                child: HomeTileBackdrop(
                  size: width,
                  base: HomeAccentPalette.wash(card.accent),
                  hill: strong,
                  badge: Align(
                    alignment: _discAlignment,
                    child: HomeLoop(
                      period: AppMotion.floatLoop,
                      reverse: true,
                      phase: (index * _phaseStep) % 1,
                      builder: (context, t, disc) => Transform.translate(
                        offset: Offset(
                          0,
                          -_float * AppMotion.machEaseInOut.transform(t),
                        ),
                        child: disc,
                      ),
                      child: Container(
                        width: _disc,
                        height: _disc,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.low,
                        ),
                        child: HomeIconView(
                          icon: card.icon,
                          size: _icon,
                          color: strong,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _labelGap),
              Text(
                card.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(height: AppSize.lh1_2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
