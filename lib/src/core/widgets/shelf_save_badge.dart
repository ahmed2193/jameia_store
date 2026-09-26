import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion.dart';
import 'shelf_arrival_scope.dart';

/// "Save 10%" on the corner of a discounted card's picture, in marker lime.
/// It pops in a beat after its card lands ([ShelfArrivalScope]).
class ShelfSaveBadge extends StatelessWidget {
  const ShelfSaveBadge({super.key, required this.percent});

  final int percent;

  static const double _poppedFrom = 0.6;

  /// The badge pops over the second half of its card's arrival.
  static const Interval _pop = Interval(0.45, 1, curve: AppMotion.emphasized);

  @override
  Widget build(BuildContext context) {
    final arrival = ShelfArrivalScope.of(context);
    return ScaleTransition(
      scale: arrival
          .drive(CurveTween(curve: _pop))
          .drive(Tween<double>(begin: _poppedFrom, end: 1)),
      // Grows out of its corner (the picture's start edge).
      alignment: AlignmentDirectional.topStart.resolve(
        Directionality.of(context),
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: AppColors.proLime,
          borderRadius: BorderRadius.circular(AppRadius.r6),
        ),
        child: Text(
          'shop.save_percent'.tr(namedArgs: {'percent': '$percent'}),
          maxLines: 1,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryText,
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
    );
  }
}
