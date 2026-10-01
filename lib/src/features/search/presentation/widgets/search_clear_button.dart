import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// The ✕ inside the search pill. It is there only while the field has text
/// (a quick fade in and out) and clears it; a 44 dp target.
class SearchClearButton extends StatelessWidget {
  const SearchClearButton({
    super.key,
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final visible = value.text.isNotEmpty;
        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          child: IgnorePointer(
            ignoring: !visible,
            child: ExcludeSemantics(
              excluding: !visible,
              child: IconButton(
                tooltip: 'search.clear_query'.tr(),
                onPressed: onClear,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(AppSize.s44),
                ),
                icon: const HeroIcon(
                  HeroIcons.closeCircleFill,
                  size: AppSize.s20,
                  color: AppColors.tertiaryText,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
