import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';

/// A white rounded tile edged in a hairline of the divider colour, whose
/// edge thickens to [selectedEdge] in [selectedColor] while it is the
/// [selected] one — easing in without moving its [child], because the
/// padding gives back what the edge takes. The size cards and the viewer's
/// thumbnails are this tile.
class PdpOutlinedTile extends StatelessWidget {
  const PdpOutlinedTile({
    super.key,
    required this.selected,
    required this.selectedColor,
    required this.radius,
    required this.inset,
    required this.child,
    this.width,
    this.height,
  });

  final bool selected;
  final Color selectedColor;
  final double radius;

  /// Edge plus padding: how far the [child] sits in from the tile's side.
  final double inset;
  final Widget child;
  final double? width;
  final double? height;

  /// The edge of the selected tile.
  static const double selectedEdge = AppSize.s2;

  /// The edge of the others.
  static const double edge = AppSize.s1;

  @override
  Widget build(BuildContext context) {
    final side = selected ? selectedEdge : edge;
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      width: width,
      height: height,
      padding: EdgeInsetsDirectional.all(inset - side),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        border: Border.all(
          color: selected ? selectedColor : AppColors.divider,
          width: side,
        ),
      ),
      child: child,
    );
  }
}
