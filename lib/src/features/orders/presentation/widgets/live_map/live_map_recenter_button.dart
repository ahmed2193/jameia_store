import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';

/// "Follow the rider again": a round white button that pops in once the
/// customer has moved the map away, and out again when it follows.
class LiveMapRecenterButton extends StatelessWidget {
  const LiveMapRecenterButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  static const double _diameter = AppSize.s48;
  static const double _hiddenScale = 0.6;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.medium);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: AppMotion.signature,
        child: AnimatedScale(
          scale: visible ? 1 : _hiddenScale,
          duration: duration,
          curve: visible ? AppSprings.snappy : AppMotion.exit,
          child: PressScale(
            pressedScale: AppMotion.pressedScaleSmall,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.medium,
              ),
              child: IconButton(
                tooltip: 'orders.live_recenter'.tr(),
                onPressed: onPressed,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(_diameter),
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryDark,
                ),
                icon: const Icon(HeroIcons.myLocation, size: AppSize.s22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
