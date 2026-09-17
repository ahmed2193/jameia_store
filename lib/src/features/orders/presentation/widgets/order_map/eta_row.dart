import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/order.dart';
import 'delivery_code_chip.dart';

class EtaRow extends StatelessWidget {
  const EtaRow({super.key, required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final delivered = order.statusStep >= 5;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            JameiaIcons.deliveryTime,
            size: 24,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                delivered ? 'map.delivered'.tr() : 'map.estimated_arrival'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                delivered
                    ? 'map.order_completed'.tr()
                    : 'map.eta_minutes'.tr(args: ['${order.etaMinutes}']),
                style: AppTextStyles.displaySmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ],
          ),
        ),
        if (!delivered)
          DeliveryCodeChip(code: order.deliveryCode)
        else
          Image.asset(
            JameiaAssets.onTimePromiseLogo,
            height: 22,
            errorBuilder: (_, _, _) => const Icon(
              JameiaIcons.confirm,
              size: 20,
              color: AppColors.success,
            ),
          ),
      ],
    );
  }
}
