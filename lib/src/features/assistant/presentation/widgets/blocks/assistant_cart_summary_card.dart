import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/price_text.dart';
import '../../../domain/entities/assistant_cart_snapshot.dart';
import 'assistant_card_frame.dart';
import 'assistant_cart_links.dart';
import 'assistant_thumbnail_strip.dart';

/// `cart_summary`: the cart as the reply saw it — count, total, a few
/// pictures and what is missing for the minimum order. The live cart is one
/// tap away.
class AssistantCartSummaryCard extends StatelessWidget {
  const AssistantCartSummaryCard({super.key, required this.cart});

  final AssistantCartSnapshot cart;

  @override
  Widget build(BuildContext context) {
    final label = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.primaryText,
    );
    return AssistantCardFrame(
      title: 'assistant.cart_summary_title'.tr(),
      icon: Icons.shopping_cart_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cart.isEmpty)
            Text('assistant.cart_empty'.tr(), style: label)
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'assistant.items'.plural(cart.itemCount),
                    style: label,
                  ),
                ),
                PriceText(price: cart.totalKd),
              ],
            ),
            if (cart.previews.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              AssistantThumbnailStrip(
                urls: [for (final item in cart.previews) item.imageUrl],
              ),
            ],
            if (cart.missingForMinOrderFils > 0) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                'assistant.min_order_gap'.tr(
                  namedArgs: {
                    'amount': Formatters.isolate(
                      Formatters.price(cart.missingForMinOrderKd),
                    ),
                  },
                ),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.warn,
                ),
              ),
            ],
          ],
          AssistantCartLinks(
            canCheckout: !cart.isEmpty && cart.missingForMinOrderFils == 0,
          ),
        ],
      ),
    );
  }
}
