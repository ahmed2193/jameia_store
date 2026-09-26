import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/branded_loader.dart';
import '../../../../../core/widgets/light_sweep.dart';

/// Covers a reward card while its points are being applied: a warm veil, a
/// light band sweeping across on a loop ([AppMotion.shimmer] per pass, no
/// rest) and the inline brand loader. Reduced motion → the veil and a still
/// loader.
class RewardApplyingOverlay extends StatelessWidget {
  const RewardApplyingOverlay({super.key});

  static const double _veilAlpha = 0.82;
  static const double _bandAlpha = 0.45;
  static final Color _veil = AppColors.accent3.withValues(alpha: _veilAlpha);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: LightSweep(
        period: AppMotion.shimmer,
        sweepShare: 1,
        peakAlpha: _bandAlpha,
        child: ColoredBox(
          color: _veil,
          child: const Center(
            child: BrandedLoader.inline(color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
