import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../config/theme/order_status_palette.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/responsive/app_size.dart';

/// Coloured pill with a dot and the status label. With the list no longer
/// split into status tabs, this is what tells the customer where an order
/// stands, so it leads its card rather than trailing it.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  static const double _dot = AppSize.s6;

  @override
  Widget build(BuildContext context) {
    final ink = OrderStatusPalette.foreground(status);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s8,
        AppSpacing.s4,
        AppSpacing.s10,
        AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: OrderStatusPalette.background(status),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s6),
          Text(
            status.labelKey.tr(),
            style: AppTextStyles.captionMedium.copyWith(
              color: ink,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ],
      ),
    );
  }
}
