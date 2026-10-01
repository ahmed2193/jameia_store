import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/pop_switcher.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/branded_dot_loader.dart';
import '../../../../core/widgets/hero_icon.dart';
import '../cubit/connectivity_banner_mode.dart';

/// The banner's icon slot (start side): no-wifi while offline, the branded
/// dots while a check runs, a check mark once back online — each swap pops.
class ConnectivityBarIcon extends StatelessWidget {
  const ConnectivityBarIcon({super.key, required this.mode});

  final ConnectivityBannerMode mode;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSize.s22,
      child: PopSwitcher(
        stateKey: mode,
        child: switch (mode) {
          ConnectivityBannerMode.reconnecting => const BrandedDotLoader(
            size: AppSize.s20,
            color: AppColors.white,
          ),
          ConnectivityBannerMode.backOnline => const HeroIcon(
            HeroIcons.checkCircleFill,
            size: AppSize.s20,
            color: AppColors.white,
          ),
          ConnectivityBannerMode.offline ||
          ConnectivityBannerMode.hidden => const HeroIcon(
            HeroIcons.offline,
            size: AppSize.s20,
            color: AppColors.white,
          ),
        },
      ),
    );
  }
}
