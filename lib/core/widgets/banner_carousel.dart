import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../data/models/models.dart';
import '../responsive/app_size.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'keeta_image.dart';

/// KeeTa promo banner carousel (`atom h45a38`): 200dp images at 12dp radius, a
/// bottom scrim with title + item count, and expanding paging dots. Extracted
/// from the Home feed so the Search Discover feed can reuse it 1:1.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<HomeBanner> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          // Real KeeTa promo banner height (atom h45a38: 200dp).
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  start: i == 0 ? AppSpacing.pageMargin : AppSpacing.s6,
                  end: i == widget.banners.length - 1
                      ? AppSpacing.pageMargin
                      : AppSpacing.s6,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      KeetaImage(url: b.image),
                      PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            8,
                            16,
                            8,
                            8,
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
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(AppRadius.card),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: AppSize.font16,
                                  fontWeight: AppTextStyles.bold,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                b.itemCount > 0
                                    ? 'home.banner_items'.tr(
                                        namedArgs: {'count': '${b.itemCount}'},
                                      )
                                    : b.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: AppSize.font12,
                                  fontWeight: AppTextStyles.regular,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.s8,
            bottom: AppSpacing.s12,
          ),
          child: SmoothPageIndicator(
            controller: _controller,
            count: widget.banners.length,
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
  }
}
