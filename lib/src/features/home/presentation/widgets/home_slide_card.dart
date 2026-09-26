import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../domain/entities/home_slide_entity.dart';
import 'home_carousel_page.dart';
import 'home_layout.dart';

/// One hero slide: the artwork with its title and description on a bottom
/// scrim. In the carousel the artwork sits a layer behind the card: as the
/// banner moves off to the side, the picture drifts the other way and grows
/// just enough to keep its edges covered.
class HomeSlideCard extends StatelessWidget {
  const HomeSlideCard({
    super.key,
    required this.slide,
    this.controller,
    this.index = 0,
  });

  final HomeSlideEntity slide;

  /// The carousel moving this banner; none for a still picture.
  final PageController? controller;

  /// The banner's place in the carousel.
  final int index;

  /// How far the picture drifts, as a share of the banner's width, a whole
  /// banner away from the middle.
  static const double _drift = 0.05;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final picture = JameiaImage(url: slide.imageUrl);
    // Against the swipe, which runs the other way under RTL.
    final against = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(HomeLayout.radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller == null)
            picture
          else
            AnimatedBuilder(
              animation: controller,
              child: picture,
              builder: (context, picture) {
                final offset = HomeCarouselPage.offsetOf(controller, index);
                return FractionalTranslation(
                  translation: Offset(against * offset * _drift, 0),
                  child: Transform.scale(
                    scale: 1 + 2 * _drift * offset.abs(),
                    child: picture,
                  ),
                );
              },
            ),
          if (slide.hasText)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s12,
                  AppSpacing.s24,
                  AppSpacing.s12,
                  AppSpacing.s10,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.bannerScrimTransparent,
                      AppColors.bannerScrim50,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slide.title.isNotEmpty)
                      Text(
                        slide.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    if (slide.description.isNotEmpty)
                      Text(
                        slide.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
