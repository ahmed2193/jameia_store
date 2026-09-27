import 'package:flutter/material.dart';

import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/checkout_thumb.dart';
import 'checkout_thumb_tile.dart';

/// One fixed 56 dp place of the order-summary strip. What it shows is keyed
/// by the line, so a new line pops into a free slot and a line that goes
/// (or shifts) crosses over in place; a re-price of the same line keeps the
/// picture and only its count bumps. Empty: blank room of the same size.
/// The first build is static, and reduced motion swaps at once.
class CheckoutThumbSlot extends StatelessWidget {
  const CheckoutThumbSlot({super.key, this.thumb});

  final CheckoutThumb? thumb;

  static const Object _empty = 'checkout-thumb-slot:empty';

  @override
  Widget build(BuildContext context) {
    final shown = thumb;
    return SizedBox.square(
      dimension: AppSize.s56,
      child: PopSwitcher(
        stateKey: shown?.id ?? _empty,
        child: shown == null
            ? const SizedBox.square(dimension: AppSize.s56)
            : CheckoutThumbTile(thumb: shown),
      ),
    );
  }
}
