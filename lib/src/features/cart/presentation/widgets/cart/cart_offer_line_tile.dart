import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_offer_line_entity.dart';
import '../../../../../core/widgets/jameia_tag.dart';
import 'cart_line_frame.dart';

/// A free product an offer put in the cart: not editable, tagged as a gift,
/// with its count ("× 2") where a paid line has its stepper.
class CartOfferLineTile extends StatelessWidget {
  const CartOfferLineTile({super.key, required this.line});

  final CartOfferLineEntity line;

  @override
  Widget build(BuildContext context) {
    return CartLineFrame(
      imageUrl: line.product.image,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.itemTitle,
          ),
          const SizedBox(height: AppSpacing.s6),
          JameiaTag(
            label: 'cart.free_gift'.tr(namedArgs: {'offer': line.offerName}),
            icon: Icons.card_giftcard_rounded,
          ),
        ],
      ),
      // "× 2" reads left-to-right in Arabic too.
      trailing: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          '× ${line.quantity}',
          style: AppTextStyles.meta.copyWith(
            fontFeatures: AppTextStyles.tabular,
          ),
        ),
      ),
    );
  }
}
