import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The spot on the ground the pin marks: a soft shadow right under its tip.
/// When the pin rises it spreads and pales, as a lifted thing's shadow does,
/// and stays on the exact point — where the pin will land.
class PickerGroundMark extends StatelessWidget {
  const PickerGroundMark({super.key, required this.lifted});

  final bool lifted;

  /// The room it takes at its widest (lifted).
  static const Size box = Size(AppSize.s16, AppSize.s6);
  static const Size _rest = Size(AppSize.s10, AppSize.s4);

  static const double _restAlpha = 0.24;
  static const double _liftedAlpha = 0.14;

  @override
  Widget build(BuildContext context) {
    final size = lifted ? box : _rest;
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(
          alpha: lifted ? _liftedAlpha : _restAlpha,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
