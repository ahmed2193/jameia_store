import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';

/// The delivery line across the top of the hero: `Deliver to <place> ⌄`,
/// white on the brand band. Tapping it opens the saved addresses.
class HomeHeroDeliverTo extends StatelessWidget {
  const HomeHeroDeliverTo({
    super.key,
    required this.placeLabel,
    required this.onTap,
  });

  final String placeLabel;
  final VoidCallback onTap;

  /// The lead-in reads quieter than the place itself.
  static const double _leadInAlpha = 0.85;
  static const double _chevronSize = AppSize.s22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: '${'home.deliver_to'.tr()} ',
                  children: [
                    TextSpan(
                      text: placeLabel,
                      style: const TextStyle(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSize.font17,
                  fontWeight: AppTextStyles.regular,
                  color: AppColors.white.withValues(alpha: _leadInAlpha),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.white,
              size: _chevronSize,
            ),
          ],
        ),
      ),
    );
  }
}
