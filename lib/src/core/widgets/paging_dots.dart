import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';

/// The app's paging dots: the expanding-dot indicator under a hero carousel or
/// a paged grid. One recipe, so no two pagers drift apart.
///
/// Renders nothing for a single page — a pager with one page is not a pager.
class PagingDots extends StatelessWidget {
  const PagingDots({super.key, required this.controller, required this.count});

  final PageController controller;
  final int count;

  static const double _expansion = 2.33;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      // The dots follow the page, and the page follows the reading direction.
      textDirection: Directionality.of(context),
      effect: const ExpandingDotsEffect(
        dotHeight: AppSize.s4,
        dotWidth: AppSize.s6,
        expansionFactor: _expansion,
        spacing: AppSize.s2,
        radius: AppSize.r2,
        activeDotColor: AppColors.primaryText,
        dotColor: AppColors.dotInactive,
      ),
    );
  }
}
