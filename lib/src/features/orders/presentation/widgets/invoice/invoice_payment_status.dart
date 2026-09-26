import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// "Paid" / "Pending" with a small status dot (green / orange). The colour
/// sits on the dot, so the label keeps the ink value style around it.
class InvoicePaymentStatus extends StatelessWidget {
  const InvoicePaymentStatus({super.key, required this.paid});

  final bool paid;

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
              color: paid ? AppColors.success : AppColors.warn,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s6),
        Flexible(
          child: Text(
            paid ? 'orders.payment_paid'.tr() : 'orders.payment_pending'.tr(),
          ),
        ),
      ],
    );
  }
}
