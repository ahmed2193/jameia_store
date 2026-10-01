import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// The bar of the store → door track at [fraction] (0 → 1): brand green as
/// far as the order has come, the rider's dot at its tip; runs from the
/// start edge, so it mirrors in Arabic.
class LiveMapTrackBar extends StatelessWidget {
  const LiveMapTrackBar({super.key, required this.fraction});

  final double fraction;

  static const double _bar = AppSize.s6;
  static const double _dot = AppSize.s14;
  static const double _ring = AppSize.s3;

  @override
  Widget build(BuildContext context) {
    const shape = BorderRadius.all(Radius.circular(AppRadius.pill));
    return SizedBox(
      height: _dot,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          const SizedBox(
            height: _bar,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.trackingLineTodo,
                borderRadius: shape,
              ),
            ),
          ),
          FractionallySizedBox(
            widthFactor: fraction,
            child: const SizedBox(
              height: _bar,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: shape,
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional(fraction * 2 - 1, 0),
            child: const SizedBox.square(
              dimension: _dot,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.primary, width: _ring),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
