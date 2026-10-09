import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/ambient_loop.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// The "there is more" arrow at the end of the first-order bar: a plain
/// white chevron (as on the reference bar) that nudges up now and then, as
/// if lifting the gift out of the bar — an [AmbientLoop] (on screen only,
/// within the ambient budget, still under reduced motion).
class HomeFirstOrderChevron extends StatelessWidget {
  const HomeFirstOrderChevron({super.key});

  static const double _glyph = AppSize.s24;
  static const double _lift = AppSize.s3;

  /// One nudge (up and back), then a still rest.
  static const Duration _nudge = AppMotion.breathe;
  static const Duration _rest = AppMotion.floatLoop;

  @override
  Widget build(BuildContext context) {
    return AmbientLoop.value(
      period: _nudge,
      rest: _rest,
      reverse: true,
      curve: AppMotion.machEaseInOut,
      valueBuilder: (context, t, child) =>
          Transform.translate(offset: Offset(0, -_lift * t), child: child),
      child: const HeroIcon(
        HeroIcons.chevronUp,
        size: _glyph,
        color: AppColors.white,
      ),
    );
  }
}
