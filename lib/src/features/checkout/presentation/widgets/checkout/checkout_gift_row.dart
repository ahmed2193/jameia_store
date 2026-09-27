import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_offer_line_entity.dart';
import '../../../../../core/widgets/jameia_money_text.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import 'checkout_line_frame.dart';
import 'checkout_red_tag.dart';

/// A free product an offer put in the basket, in the items sheet: the same
/// row as a paid line, tagged with the offer's name, "1x", the product's
/// struck price and "Free" at the end. It selects its own gift ([giftKey]),
/// so a re-price rebuilds it only when that gift changed.
class CheckoutGiftRow extends StatelessWidget {
  const CheckoutGiftRow({super.key, required this.giftKey});

  /// A gift row's identity in the items list.
  static Key keyFor(String giftKey) => ValueKey<String>('gift:$giftKey');

  final String giftKey;

  @override
  Widget build(BuildContext context) {
    final gift = context.select<CartCubit, CartOfferLineEntity?>(
      (cubit) => cubit.state.cart.offerLines
          .where((gift) => gift.key == giftKey)
          .firstOrNull,
    );
    if (gift == null) return const SizedBox.shrink();
    final strong = AppTextStyles.label.copyWith(
      fontWeight: AppTextStyles.bold,
      color: AppColors.primaryText,
    );
    final product = gift.product;
    return CheckoutLineFrame(
      imageUrl: product.image,
      top: Text(
        product.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: strong,
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gift.offerName.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s4,
              ),
              child: CheckoutRedTag(label: gift.offerName),
            ),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.s6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        'checkout.qty_times'.tr(
                          namedArgs: {'count': '${gift.quantity}'},
                        ),
                        style: strong,
                      ),
                    ),
                    if (product.hasListPrice)
                      JameiaMoneyText(
                        kd: product.priceKd,
                        strike: true,
                        style: AppTextStyles.bodySmall,
                        color: AppColors.tertiaryText,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'checkout.summary_free'.tr(),
                style: strong.copyWith(color: AppColors.freeDelivery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
