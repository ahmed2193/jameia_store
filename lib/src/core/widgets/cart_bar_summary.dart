import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'cart_basket_badge.dart';
import 'cart_delivery_note.dart';
import 'jameia_bar_total.dart';
import 'jameia_money_text.dart';

/// The start of a basket bar ("View cart", "Checkout"): the green basket
/// with its count ([CartBasketBadge]), the amount in bold — its digits roll
/// to a new value — with an optional struck amount beside it, and the
/// delivery line under it ([CartDeliveryNote]) when there is one to show.
/// Every number arrives decided by the server's cart.
class CartBarSummary extends StatelessWidget {
  const CartBarSummary({
    super.key,
    required this.count,
    required this.amountKd,
    this.struckKd,
    this.deliveryKd,
    this.placeholder = '',
    this.targetKey,
  });

  final int count;

  /// `null` while the amount is being re-priced: [placeholder] shows
  /// ("Updating…") and the last amount rolls to the new one when it lands.
  final double? amountKd;

  /// What the amount was before its discounts, struck; `null` = none.
  final double? struckKd;

  /// `0` = free delivery, more = the fee, `null` = no delivery line.
  final double? deliveryKd;
  final String placeholder;

  /// The basket, as the place added products fly to.
  final GlobalKey? targetKey;

  @override
  Widget build(BuildContext context) {
    final struck = struckKd;
    final delivery = deliveryKd;
    return Row(
      children: [
        CartBasketBadge(count: count, targetKey: targetKey),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    JameiaBarTotal(
                      kd: amountKd,
                      placeholder: placeholder,
                      alignment: AlignmentDirectional.centerStart,
                      style: AppTextStyles.sectionTitle,
                      placeholderStyle: AppTextStyles.meta,
                    ),
                    if (struck != null && amountKd != null) ...[
                      const SizedBox(width: AppSpacing.s6),
                      JameiaMoneyText(
                        kd: struck,
                        strike: true,
                        color: AppColors.tertiaryText,
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
              if (delivery != null) ...[
                const SizedBox(height: AppSpacing.s2),
                CartDeliveryNote(kd: delivery),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
