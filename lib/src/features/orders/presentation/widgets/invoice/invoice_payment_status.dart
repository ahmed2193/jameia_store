import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/order_payment_standing.dart';

/// Where the payment stands — "Paid", "Pay on delivery", "Not charged",
/// "Pending", the words of the order page and the PDF — with a small status
/// dot (green / red / orange). The colour sits on the dot, so the label
/// keeps the ink value style around it.
class InvoicePaymentStatus extends StatelessWidget {
  const InvoicePaymentStatus({super.key, required this.standing});

  final OrderPaymentStanding standing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: AppSize.s8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (standing) {
                OrderPaymentStanding.paid => AppColors.success,
                OrderPaymentStanding.notCharged => AppColors.errorDeep,
                OrderPaymentStanding.dueOnDelivery ||
                OrderPaymentStanding.pending => AppColors.warn,
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s6),
        Flexible(child: Text(standing.labelKey.tr())),
      ],
    );
  }
}
