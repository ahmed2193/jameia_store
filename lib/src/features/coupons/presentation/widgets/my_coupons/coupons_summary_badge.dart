import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// The ticket glyph at the corner of the savings card: a white disc with a
/// soft breathing glow behind it ([FloatLoop.glow]; a still glow under reduced
/// motion). Both wait for the card to land ([AfterArrival], backlog B2-03):
/// the disc pops and the glow starts once the card has risen in, not with
/// it. Decorative only.
class CouponsSummaryBadge extends StatelessWidget {
  const CouponsSummaryBadge({super.key});

  static const double _glowDiameter = AppSize.s80;
  static const double _discDiameter = AppSize.s48;

  static const Widget _disc = DecoratedBox(
    decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
    child: SizedBox.square(
      dimension: _discDiameter,
      child: HeroIcon(
        HeroIcons.voucher,
        size: AppSize.s28,
        color: kHeroPillPin,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _glowDiameter,
        child: AfterArrival(
          builder: (context, landed) => Stack(
            alignment: Alignment.center,
            children: [
              FloatLoop.glow(
                color: AppColors.white,
                diameter: _glowDiameter,
                active: landed,
              ),
              if (landed)
                const PopScale.onMount(child: _disc)
              else
                const Visibility.maintain(visible: false, child: _disc),
            ],
          ),
        ),
      ),
    );
  }
}
