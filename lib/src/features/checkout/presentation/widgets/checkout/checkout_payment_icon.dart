import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon_plate.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';

/// The 22 dp mark at the start of a payment row: a Hero [icon] white on its
/// [HeroIconPlate] (the cash note, `HeroIcons.cash`, on brand green) or a
/// colour [plate] (the yellow wallet, `HeroAssets.checkoutWallet`).
/// Decorative: the row's title names the method.
class CheckoutPaymentIcon extends StatelessWidget {
  const CheckoutPaymentIcon({super.key, this.icon, this.plate})
    : assert((icon == null) != (plate == null), 'an icon or a plate');

  static const double size = AppSize.s22;

  final IconData? icon;
  final String? plate;

  @override
  Widget build(BuildContext context) => switch (plate) {
    final String art => HeroSvgGlyph.art(art, size: size),
    null => HeroIconPlate(icon!, size: size),
  };
}
