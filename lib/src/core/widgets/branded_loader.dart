import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';
import 'branded_dot_loader.dart';

/// The Hero loader dots on a brand fill — a button, a green pill: white and
/// the cape's light yellow by default, the pair that reads on the green.
/// Pass [color] (and [trailColor]) for another fill. On a light surface use
/// [BrandedDotLoader]; for a block load, `AppLoader`.
class BrandedLoader extends StatelessWidget {
  const BrandedLoader.inline({
    super.key,
    this.size = AppSize.s22,
    this.color = AppColors.brandForeground,
    this.trailColor = AppColors.accent4,
  });

  final double size;

  /// The lead dot.
  final Color color;

  /// The dot circling it.
  final Color trailColor;

  @override
  Widget build(BuildContext context) =>
      BrandedDotLoader(size: size, color: color, trailColor: trailColor);
}
