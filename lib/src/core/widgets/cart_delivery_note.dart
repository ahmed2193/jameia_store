import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_icon_tone.dart';
import '../design/hero_icons.dart';
import '../responsive/app_size.dart';
import '../utils/formatters.dart';
import 'hero_icon.dart';

/// The delivery line under a basket bar's amount: the Hero scooter and "Free
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HeroIcon(
          HeroIcons.delivery,
          tone: HeroIconTone.brand,
          size: _rider,
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
