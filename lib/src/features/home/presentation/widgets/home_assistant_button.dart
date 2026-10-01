import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import 'home_notifications_bell.dart';

/// The assistant entry of the home header: a brand-tinted disc with the
/// Hero assistant glyph (the mascot's gumdrop + sparkle), the bell's size so
/// the two sit as a pair, inside a 48 dp touch box ([hitSize]; it overhangs
/// the disc by [inset] on every side).
class HomeAssistantButton extends StatelessWidget {
  const HomeAssistantButton({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double discSize = HomeNotificationsBell.discSize;
  static const double hitSize = AppSize.s48;
  static const double inset = (hitSize - discSize) / 2;

  @override
  Widget build(BuildContext context) {
    final label = 'assistant.entry'.tr();
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: PressScale(
          onTap: onTap,
          child: const SizedBox.square(
            dimension: hitSize,
            child: Center(
              child: SizedBox.square(
                dimension: discSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.brandLightBg,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.brandTileBorder),
                    ),
                  ),
                  child: Center(
                    child: HeroIcon(
                      HeroIcons.assistant,
                      size: AppSize.s20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
