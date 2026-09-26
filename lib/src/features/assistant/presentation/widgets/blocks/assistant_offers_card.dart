import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';
import 'assistant_card_link.dart';
import 'assistant_coupon_chip.dart';
import 'assistant_offer_row.dart';

/// `offers`: the running promotions (applied by the cart itself) and, when
/// the assistant has one, a coupon code to copy.
class AssistantOffersCard extends StatelessWidget {
  const AssistantOffersCard({super.key, required this.block});

  final AssistantOffersBlock block;

  @override
  Widget build(BuildContext context) {
    final code = block.couponCode;
    return AssistantCardFrame(
      title: 'assistant.offers_title'.tr(),
      icon: Icons.local_offer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final offer in block.offers) AssistantOfferRow(offer: offer),
          if (code != null && block.hasCoupon) ...[
            const SizedBox(height: AppSpacing.s4),
            AssistantCouponChip(code: code),
          ],
          if (block.offers.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AssistantCardLink(
                label: 'assistant.offers_all'.tr(),
                onTap: () => context.push(Routes.offers),
              ),
            ),
        ],
      ),
    );
  }
}
