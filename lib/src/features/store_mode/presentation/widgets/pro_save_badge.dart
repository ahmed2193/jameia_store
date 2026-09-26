import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/widgets/light_sweep.dart';

/// Lime "Save N%" chip riding on the best-value plan's tab: pops in the first
/// time it shows, then a gentle shine sweeps across it now and then.
class ProSaveBadge extends StatelessWidget {
  const ProSaveBadge({super.key, required this.percent});

  /// White on lime needs a brighter glint than on a dark fill.
  static const double _glintAlpha = 0.7;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.chip),
  );

  final int percent;

  @override
  Widget build(BuildContext context) {
    return PopScale.onMount(
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: _radius,
          child: LightSweep(
            peakAlpha: _glintAlpha,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.proLime,
                borderRadius: _radius,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s2,
                ),
                child: Text(
                  'pro.save_percent'.tr(namedArgs: {'percent': '$percent'}),
                  maxLines: 1,
                  style: AppTextStyles.subheadingSmall.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
