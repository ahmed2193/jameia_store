import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common.dart';
import '../../../domain/entities/order.dart';
import 'contact_action.dart';

class RiderRow extends StatelessWidget {
  const RiderRow({super.key, required this.rider});
  final RiderEntity rider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.smallBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            KeetaIcons.delivery,
            size: 22,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rider.name,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  RatingBadge(rating: rider.rating, count: rider.reviews),
                  const SizedBox(width: AppSpacing.s8),
                  Flexible(
                    child: Text(
                      '· ${rider.vehicle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ContactAction(
          icon: KeetaIcons.chat,
          filled: false,
          onTap: () =>
              _toast(context, 'map.opening_chat'.tr(args: [rider.name])),
        ),
        const SizedBox(width: AppSpacing.s8),
        ContactAction(
          icon: KeetaIcons.phone,
          filled: true,
          onTap: () => _toast(context, 'map.calling'.tr(args: [rider.name])),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
