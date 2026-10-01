import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// The flat round plate an empty / error / signed-out state leads with: an
/// 88 dp muted circle and a 40 dp icon ([dimension] / [iconSize] for a
/// smaller plate, e.g. a confirmation dialog's 64 dp).
class StateIconPlate extends StatelessWidget {
  const StateIconPlate({
    super.key,
    required this.icon,
    this.color = AppColors.secondaryText,
    this.fill = AppColors.smallBackground,
    this.dimension = AppSize.s88,
    this.iconSize = AppSize.s40,
  });

  final IconData icon;
  final Color color;
  final Color fill;
  final double dimension;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: HeroIcon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
