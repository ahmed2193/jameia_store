import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

/// Jameia `c_search_shop` "Delivery | Pickup" tab bar. Two 50% tabs on a grey
/// (`#F5F6FA`) backdrop; the active tab is raised white with rounded top
/// corners (connecting to the white filter row below), the inactive tab is
/// recessed grey with a dimmed (opacity 0.3) label. 42dp tall.
class DeliveryPickupTabs extends StatelessWidget {
  const DeliveryPickupTabs({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index; // 0 = Delivery, 1 = Pickup
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mediumBackground, // recessed backdrop #F5F6FA
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            _Tab(
              label: 'search.delivery'.tr(),
              active: index == 0,
              corner: const BorderRadiusDirectional.only(
                topStart: Radius.circular(AppSize.r16),
                topEnd: Radius.circular(AppSize.r16),
              ),
              onTap: () => onChanged(0),
            ),
            _Tab(
              label: 'search.pickup'.tr(),
              active: index == 1,
              corner: const BorderRadiusDirectional.only(
                topStart: Radius.circular(AppSize.r16),
                topEnd: Radius.circular(AppSize.r16),
              ),
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.corner,
    required this.onTap,
  });

  final String label;
  final bool active;
  final BorderRadiusGeometry corner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? AppColors.white : Colors.transparent,
            borderRadius: active ? corner : null,
          ),
          child: Center(
            child: Opacity(
              opacity: active ? 1 : 0.3,
              child: Text(
                label,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.black,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
