import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// One big digit of the saved delivery code on a warm cream tile. When the
/// code changes, only the digits that differ flip.
class DeliveryCodeDigitBox extends StatelessWidget {
  const DeliveryCodeDigitBox({super.key, required this.digit});

  static const double height = AppSize.s72;

  /// The digit, or `''` while the code loads.
  final String digit;

  static final TextStyle _style = AppTextStyles.displayLarge.copyWith(
    fontSize: AppSize.font40,
    height: AppSize.lh1_2,
    fontWeight: AppTextStyles.bold,
    color: AppColors.voucherBrown,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.deliveryCodeBg,
          borderRadius: BorderRadius.circular(AppRadius.r3),
          border: Border.all(color: AppColors.accent4Dark),
        ),
        child: ClipRect(
          child: RepaintBoundary(
            child: FlipValue(
              flipKey: digit,
              alignment: AlignmentDirectional.center,
              child: Center(child: Text(digit, style: _style)),
            ),
          ),
        ),
      ),
    );
  }
}
