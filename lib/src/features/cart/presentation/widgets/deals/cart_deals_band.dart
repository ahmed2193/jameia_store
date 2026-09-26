import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import 'cart_deal_cards_row.dart';
import 'cart_deals_header.dart';

/// The sheet's green-washed top: the head and the offers row, the selected
/// card's pointer resting on the white grid below.
class CartDealsBand extends StatelessWidget {
  const CartDealsBand({super.key});

  static const LinearGradient _wash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.brandLightBg, AppColors.accent2Light],
  );

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: _wash),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [CartDealsHeader(), CartDealCardsRow()],
      ),
    );
  }
}
