import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_layout.dart';

/// "Delivering in 40 mins" — the accent-outlined pill under the store name,
/// from the ETA of the customer's delivery zone. It pops in when the ETA
/// lands.
class HomeEtaPill extends StatelessWidget {
  const HomeEtaPill({super.key, required this.minutes});

  final int minutes;

  static const double _verticalPad = AppSpacing.s3;
  static const double _border = AppSize.s1_2;

  /// Line height of the label before the reader's text scale.
  static const double _line = AppSize.s16;

  /// The height the pill takes at [textScaler]; the header reserves it.
  static double heightFor(TextScaler textScaler) =>
      textScaler.scale(_line) + 2 * (_verticalPad + _border);

  @override
  Widget build(BuildContext context) {
    return PopScale.onMount(
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s8,
          _verticalPad,
          AppSpacing.s10,
          _verticalPad,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: HomeLayout.accent, width: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.rocket_launch_rounded,
              size: AppSize.s14,
              color: HomeLayout.accent,
            ),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                'home.delivering_in'.tr(namedArgs: {'minutes': '$minutes'}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
