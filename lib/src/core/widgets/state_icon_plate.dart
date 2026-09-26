import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';

/// The flat round plate an empty / error / signed-out state leads with: an
/// 88 dp muted circle and a 40 dp icon.
class StateIconPlate extends StatelessWidget {
  const StateIconPlate({
    super.key,
    required this.icon,
    this.color = AppColors.secondaryText,
    this.fill = AppColors.smallBackground,
  });

  final IconData icon;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSize.s88,
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: Icon(icon, size: AppSize.s40, color: color),
        ),
      ),
    );
  }
}
