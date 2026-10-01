import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/pop_scale.dart';
import '../../../../../core/responsive/app_size.dart';

/// The headline once the rider is at the door: the Hero check pops in
/// beside "Your rider is here" (read out as it appears).
class LiveMapArrivedTitle extends StatelessWidget {
  const LiveMapArrivedTitle({super.key});

  static const double _check = AppSize.s28;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const PopScale.onMount(
            child: Icon(
              HeroIcons.checkCircleFill,
              size: _check,
              color: AppColors.brandDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'orders.live_arrived_title'.tr(),
              style: AppTextStyles.displaySmall,
            ),
          ),
        ],
      ),
    );
  }
}
