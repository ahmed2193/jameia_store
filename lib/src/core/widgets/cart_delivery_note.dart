import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_assets.dart';
import '../responsive/app_size.dart';
import '../utils/formatters.dart';

/// The delivery line under a basket bar's amount: the rider and "Free
/// delivery" when [kd] is `0`, or "KD 0.650 delivery" — the server's quote
/// (`CartEntity.deliveryQuoteKd`).
class CartDeliveryNote extends StatelessWidget {
  const CartDeliveryNote({super.key, required this.kd});

  final double kd;

  static const double _rider = AppSize.s18;

  @override
  Widget build(BuildContext context) {
    final free = kd <= 0;
    final text = free
        ? 'core.free_delivery'.tr()
        : 'core.delivery_fee_amount'.tr(
            namedArgs: {'amount': Formatters.price(kd)},
          );
    final decode = (_rider * MediaQuery.devicePixelRatioOf(context)).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          HeroAssets.globalRider,
          width: _rider,
          height: _rider,
          cacheWidth: decode,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: AppSpacing.s6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: free ? AppColors.labelGrey : AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
