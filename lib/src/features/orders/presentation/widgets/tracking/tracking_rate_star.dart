import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';

/// One star of the "How was your order?" card: a 44 dp target that gives
/// under the finger and opens the review with [value] stars chosen.
class TrackingRateStar extends StatelessWidget {
  const TrackingRateStar({
    super.key,
    required this.value,
    required this.onPressed,
    this.max = 5,
  });

  final int value;
  final VoidCallback onPressed;

  /// Stars on the card (the label reads "n of max").
  final int max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'orders.review_star_label'.tr(
        namedArgs: {'count': '$value', 'max': '$max'},
      ),
      child: ExcludeSemantics(
        child: PressScale(
          child: InkResponse(
            onTap: onPressed,
            radius: AppSize.s22,
            child: const SizedBox.square(
              dimension: AppSize.s44,
              child: Icon(
                HeroIcons.star,
                size: AppSize.s32,
                color: AppColors.trackingLineTodo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
