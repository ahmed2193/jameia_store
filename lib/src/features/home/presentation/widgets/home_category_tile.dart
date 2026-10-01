import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import '../../../../core/widgets/hero_image.dart';
import '../../domain/entities/home_icon.dart';
import 'home_accent_palette.dart';
import 'home_category_aurora_painter.dart';
import 'home_layout.dart';

/// One aisle tile of the storefront: the category photo on a round white
/// plate over a softly moving wash, and the name centred underneath.
///
/// The wash takes its colour from the tile's place on the shelf ([index]),
/// so neighbours differ, and moves on the shelf's shared [ambient] clock —
/// one ticker for the whole shelf, each tile starting further round the lap.
class HomeCategoryTile extends StatelessWidget {
  const HomeCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    this.index = 0,
    this.ambient = kAlwaysCompleteAnimation,
  });

  final CatalogCategoryEntity category;
  final VoidCallback onTap;

  /// The tile's place on the shelf: picks its colour and where its glow
  /// starts.
  final int index;

  /// The shelf's looping clock (0 → 1 per lap). A still wash by default.
  final Animation<double> ambient;

  /// Width of the cell and side of its square tile.
  static const double width = AppSize.s80;

  /// The colours the shelf cycles through, in order. Five, so a tile never
  /// matches the one beside it in either row.
  static const List<HomeAccent> washes = [
    HomeAccent.amber,
    HomeAccent.emerald,
    HomeAccent.sky,
    HomeAccent.violet,
    HomeAccent.rose,
  ];

  /// The colour of the tile at [index] on the shelf.
  static HomeAccent accentAt(int index) => washes[index % washes.length];

  static const double _plate = AppSize.s60;
  static const double _ring = AppSize.s2;
  static const double _photo = _plate - 2 * _ring;
  static const double _labelGap = AppSpacing.s6;

  /// Two lines of the name before the reader's text scale.
  static const double _labelLines = AppSize.s34;
  static const double _fallbackGlyph = AppSize.s28;

  /// Golden-ratio steps round the lap never line two neighbours up.
  static const double _phaseStep = 0.618;

  /// The height a row owes this tile at the reader's text scale.
  static double cellHeight(BuildContext context) =>
      width + _labelGap + MediaQuery.textScalerOf(context).scale(_labelLines);

  @override
  Widget build(BuildContext context) {
    final accent = accentAt(index);
    final strong = HomeAccentPalette.strong(accent);
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              SizedBox.square(
                dimension: width,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      // The wash repaints every frame; the plate and the
                      // name above it stay recorded.
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: HomeCategoryAuroraPainter(
                            progress: ambient,
                            phase: (index * _phaseStep) % 1,
                            base: HomeAccentPalette.wash(accent),
                            glow: strong,
                            radius: HomeLayout.radius,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: _plate,
                      height: _plate,
                      padding: const EdgeInsets.all(_ring),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.low,
                      ),
                      child: category.hasImage
                          ? HeroImage.circle(url: category.image, size: _photo)
                          // Some of the store's categories have no image.
                          : HeroIcon(
                              HeroIcons.category,
                              size: _fallbackGlyph,
                              color: strong,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _labelGap),
              Text(
                category.name,
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
