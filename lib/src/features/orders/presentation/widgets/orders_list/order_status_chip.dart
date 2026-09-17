import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  // Bundle: ha1c5d — padding 2dp 6dp, font Jameia-SemiBold 10dp (caption-medium),
  // border-radius 4.8dp; a8ec87 (warn bg FFFEEB). Colors per system-state tokens.
  ({String label, Color fg, Color bg}) get _style {
    switch (status) {
      case 'delivering':
        // warn-dark #EE7F00 / warn-light #FFFEEB (ha1c5d + a8ec87)
        return (
          label: 'orders.status_delivering'.tr(),
          fg: AppColors.warn,
          bg: AppColors.warnBg,
        );
      case 'preparing':
        // blue link #1963CC / blue[0] light bg
        return (
          label: 'orders.status_preparing'.tr(),
          fg: AppColors.link,
          bg: AppColors.blue[0],
        );
      case 'completed':
        // green freeDelivery / freeDeliveryBg
        return (
          label: 'orders.status_completed'.tr(),
          fg: AppColors.freeDelivery,
          bg: AppColors.freeDeliveryBg,
        );
      case 'cancelled':
        // error red / errorBg
        return (
          label: 'orders.status_cancelled'.tr(),
          fg: AppColors.error,
          bg: AppColors.errorBg,
        );
      default:
        return (
          label: status.isEmpty ? 'orders.status_unknown'.tr() : status,
          fg: AppColors.secondaryText,
          bg: AppColors.smallBackground,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      // Bundle: ha1c5d — padding 2dp 6dp (V/H); a8ec87 border-radius 4.8dp
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(AppSize.r4_8),
      ),
      child: Text(
        s.label,
        style: AppTextStyles.captionMedium.copyWith(
          // Bundle: Jameia-SemiBold (w600) 10dp
          color: s.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
