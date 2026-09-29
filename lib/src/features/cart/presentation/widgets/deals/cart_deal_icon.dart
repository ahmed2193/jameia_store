import 'package:flutter/material.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/offer_reward_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/offer_plate.dart';

/// The rounded glyph of a deal card: the scooter for free delivery, a gift
/// for a free product, the "%" plate for a percentage off, a voucher for any
/// other discount.
class CartDealIcon extends StatelessWidget {
  const CartDealIcon({super.key, required this.type});

  final OfferRewardType type;

  static const double _size = AppSize.s20;

  @override
  Widget build(BuildContext context) {
    return OfferPlate(
      asset: OfferPlate.assetFor(type) ?? HeroAssets.offerVoucher,
      size: _size,
    );
  }
}
