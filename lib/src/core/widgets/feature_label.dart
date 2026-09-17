import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';

/// Feature label (e.g. "Buy 1 Get 1", "Low delivery fee") — outlined neutral
/// chip used in the golden card feature row.
class FeatureLabel extends StatelessWidget {
  const FeatureLabel({super.key, required this.text, this.height = 18});

  final String text;
  final double height;

  static const double _tightLineHeight = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandLightBg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: AppSize.font11,
          height: _tightLineHeight,
          color: AppColors.promotionTagFg,
        ),
      ),
    );
  }
}
