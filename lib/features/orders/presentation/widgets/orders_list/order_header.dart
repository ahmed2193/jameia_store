import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/keeta_image.dart';
import '../../../domain/entities/order.dart';
import '../../util/order_display.dart';
import 'order_status_chip.dart';

class OrderHeader extends StatelessWidget {
  const OrderHeader({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bundle: h48395 — width 40dp, height 40dp, border-radius 13dp (r4)
        KeetaImage(
          url: order.shopLogo,
          width: AppSpacing.s40,
          height: AppSpacing.s40,
          radius: AppRadius.r4, // 13dp
        ),
        const SizedBox(width: AppSpacing.s8),
        // Bundle: e57ef2 — KeeTa-Bold 16dp #222222 flex:1, ellipsis 1 line
        Expanded(
          child: Text(
            order.displayShopName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        OrderStatusChip(status: order.status),
      ],
    );
  }
}
