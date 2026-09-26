import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// The Mine header's backdrop at collapse [progress] (0 open → 1 collapsed):
/// a soft brand-green wash melting into the page, with a faint ring in the
/// top-end corner; it settles to a plain white bar with a soft shadow as the
/// menu scrolls under it. Only colours change — the blur never animates.
class MineHeaderBackground extends StatelessWidget {
  const MineHeaderBackground({super.key, required this.progress});

  final double progress;

  static const Interval _shadowIn = Interval(0.8, 1);
  static const double _ringAlpha = 0.55;
  static const double _ringOverhang = -AppSpacing.s48;
  static const double _ringWidth = AppSpacing.s24;
  static const double _ringSize = AppSize.s180;
  static const Offset _shadowOffset = Offset(0, AppSize.s2);

  @override
  Widget build(BuildContext context) {
    final top = Color.lerp(AppColors.brandLightBg, AppColors.white, progress)!;
    final bottom = Color.lerp(
      AppColors.mediumBackground,
      AppColors.white,
      progress,
    )!;
    final shadow = AppColors.shadowInk10.withValues(
      alpha: AppColors.shadowInk10.a * _shadowIn.transform(progress),
    );
    final ring = AppColors.white.withValues(alpha: _ringAlpha * (1 - progress));
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        boxShadow: [
          BoxShadow(
            color: shadow,
            offset: _shadowOffset,
            blurRadius: AppSize.s8,
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          children: [
            PositionedDirectional(
              top: _ringOverhang,
              end: _ringOverhang,
              child: SizedBox.square(
                dimension: _ringSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: _ringWidth),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
