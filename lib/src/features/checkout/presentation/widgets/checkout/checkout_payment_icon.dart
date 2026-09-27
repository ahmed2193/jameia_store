import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/responsive/app_size.dart';

/// The 22 dp art at the start of a payment row (Hero's plates): the cash
/// note or the yellow wallet plate (`HeroAssets.checkoutCash` /
/// `checkoutWallet`). Decorative: the row's title names the method.
class CheckoutPaymentIcon extends StatelessWidget {
  const CheckoutPaymentIcon({super.key, required this.asset});

  static const double size = AppSize.s22;

  final String asset;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
