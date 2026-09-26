import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/responsive/app_size.dart';

/// The tinted disc at the start of an offer card: a truck for free delivery,
/// a percent sign for a percentage off, a tag for money off, a gift for a
/// free item. Decorative: the card's text says the same.
class OfferRewardDisc extends StatelessWidget {
  const OfferRewardDisc({super.key, required this.type});

  final OfferRewardType type;

  static const double size = AppSize.s52;
  static const double _glyph = AppSize.s24;

  @override
  Widget build(BuildContext context) {
    final (icon, ink, plate) = switch (type) {
      OfferRewardType.freeDelivery => (
        Icons.local_shipping_outlined,
        AppColors.freeDeliveryFgOnLight,
        AppColors.freeDeliveryBg,
      ),
      OfferRewardType.percentageDiscount => (
        Icons.percent_rounded,
        AppColors.accent3Dark,
        AppColors.accent3Light,
      ),
      OfferRewardType.fixedDiscount => (
        Icons.sell_outlined,
        AppColors.accent1Dark,
        AppColors.accent1Light,
      ),
      OfferRewardType.freeProduct => (
        Icons.card_giftcard_rounded,
        AppColors.accentViolet,
        AppColors.accentVioletLight,
      ),
      OfferRewardType.other => (
        Icons.local_offer_outlined,
        AppColors.primaryText,
        AppColors.smallBackground,
      ),
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: plate, shape: BoxShape.circle),
        child: Icon(icon, size: _glyph, color: ink),
      ),
    );
  }
}
