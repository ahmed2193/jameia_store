import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/order.dart';

// ── Floating ETA bubble (top) ────────────────────────────────────────────────

/// Pill bubble — yellow circle icon + "Estimated arrival" / "{eta} min"
/// (RE §2.2 / §8: h46, radius16, h-pad10, soft shadow).
class MapEtaBubble extends StatelessWidget {
  const MapEtaBubble({super.key, required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.only(start: 6, end: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3), // r16
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              KeetaIcons.deliveryTime,
              size: 18,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'map.estimated_arrival'.tr(),
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
              Text(
                'map.eta_minutes'.tr(args: ['${order.etaMinutes}']),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
