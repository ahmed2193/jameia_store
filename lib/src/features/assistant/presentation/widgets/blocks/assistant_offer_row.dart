import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/offer_entity.dart';
import '../../../../../core/utils/formatters.dart';

/// One promotion: its name, the server's description and, for a spend
/// threshold, how much to spend.
class AssistantOfferRow extends StatelessWidget {
  const AssistantOfferRow({super.key, required this.offer});

  final OfferEntity offer;

  @override
  Widget build(BuildContext context) {
    final threshold =
        offer.triggerType == OfferTriggerType.cartSubtotal &&
        offer.minSubtotalFils > 0;
    final caption = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: AppTextStyles.bold,
            ),
          ),
          if (offer.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              offer.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: caption,
            ),
          ],
          if (threshold) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              'assistant.offer_min'.tr(
                namedArgs: {
                  'amount': Formatters.isolate(
                    Formatters.price(offer.minSubtotalKd),
                  ),
                },
              ),
              style: caption.copyWith(color: AppColors.finalPrice),
            ),
          ],
        ],
      ),
    );
  }
}
