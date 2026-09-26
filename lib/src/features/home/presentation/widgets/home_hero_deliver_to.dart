import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_layout.dart';
import 'home_pressable.dart';

/// The delivery line of the header: `📍 Deliver to <place> ⌄`, ink on the
/// white header. Tapping it opens the saved addresses.
class HomeHeroDeliverTo extends StatelessWidget {
  const HomeHeroDeliverTo({
    super.key,
    required this.placeLabel,
    required this.onTap,
  });

  final String placeLabel;
  final VoidCallback onTap;

  /// Line height of the text before the reader's text scale.
  static const double _line = AppSize.s19;
  static const double _chevronSize = AppSize.s20;

  /// The height the line takes at [textScaler]; the header reserves it.
  static double heightFor(TextScaler textScaler) {
    final text = textScaler.scale(_line);
    return text > _chevronSize ? text : _chevronSize;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: HomePressable(
        child: GestureDetector(
          onTap: () {
            Haptics.tap();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: AppSize.s18,
                color: HomeLayout.accent,
              ),
              const SizedBox(width: AppSpacing.s4),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: '${'home.deliver_to'.tr()} ',
                    children: [
                      TextSpan(
                        text: placeLabel,
                        style: const TextStyle(
                          fontWeight: AppTextStyles.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: kJameiaPillChevron,
                size: _chevronSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
