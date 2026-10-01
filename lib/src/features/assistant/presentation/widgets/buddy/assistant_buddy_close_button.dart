import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// "Not now" on the greeting: a small grey disc, a full-size touch target.
class AssistantBuddyCloseButton extends StatelessWidget {
  const AssistantBuddyCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'assistant.buddy_close'.tr(),
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        child: const SizedBox.square(
          dimension: AppSize.s44,
          child: Center(
            child: SizedBox.square(
              dimension: AppSize.s28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.smallBackground,
                  shape: BoxShape.circle,
                ),
                child: HeroIcon(
                  HeroIcons.close,
                  size: AppSize.s18,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
