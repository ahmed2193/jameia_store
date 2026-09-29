import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../responsive/app_size.dart';
import 'branded_dot_painter.dart';

/// The pull-to-refresh disc: a small white [LoaderDisc] whose dots stand at
/// [dots] (the pull while the finger is down, the loop while refreshing);
/// [opacity] fades them (the reduced-motion breathe while refreshing).
class RefreshDisc extends StatelessWidget {
  const RefreshDisc({super.key, required this.dots, this.opacity});

  static const double diameter = AppSize.s44;
  static const double _dotsWidth = AppSize.s18;

  /// The dots' loop position ([BrandedDotPainter.phase]).
  final Animation<double> dots;

  /// The dots' opacity ([BrandedDotPainter.opacity]); null = full.
  final Animation<double>? opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.loaderDisc,
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(
              _dotsWidth,
              _dotsWidth * BrandedDotPainter.heightShare,
            ),
            painter: BrandedDotPainter(
              phase: dots,
              lead: AppColors.primary,
              trail: AppColors.proAmber,
              opacity: opacity,
            ),
          ),
        ),
      ),
    );
  }
}
