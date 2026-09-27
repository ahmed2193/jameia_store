import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';
import 'sticker_text.dart';

/// One red box of a [CountdownDigits] clock ("06"): white sticker digits in
/// tabular figures on the deal-tag red, 3 dp corners. At least [side] square,
/// and it grows with the text scale instead of clipping.
class CountdownDigitBox extends StatelessWidget {
  const CountdownDigitBox({super.key, required this.digits});

  /// The smallest box (the Hero boxes measure 13–14 dp).
  static const double side = AppSize.s14;

  static const BoxDecoration _fill = BoxDecoration(
    color: AppColors.couponBadgeRed,
    borderRadius: BorderRadius.all(Radius.circular(AppSize.r3)),
  );

  final String digits;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _fill,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: side, minHeight: side),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s1,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: StickerText(
              digits,
              rim: AppSize.s2,
              textAlign: TextAlign.center,
              style: AppTextStyles.tag.copyWith(
                fontSize: AppSize.font11,
                height: AppSize.lh1_2,
                color: AppColors.white,
                fontFeatures: AppTextStyles.tabular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
