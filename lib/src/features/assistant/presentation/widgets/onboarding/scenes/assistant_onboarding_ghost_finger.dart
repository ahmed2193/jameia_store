import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../core/motion/motion.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../assistant_onboarding_timeline.dart';

/// A see-through finger that shows how the cart demo works when the
/// customer does not try it: it glides from [from] to [to] (fingertip
/// points, start-based in the stage's design space), presses, a ring
/// spreads from the tap, and it fades away — over [progress] `0 → 1`.
/// Must sit directly in the scene's `Stack`.
class AssistantOnboardingGhostFinger extends StatelessWidget {
  const AssistantOnboardingGhostFinger({
    super.key,
    required this.progress,
    required this.from,
    required this.to,
  });

  final double progress;
  final Offset from;
  final Offset to;

  /// Where the tap lands in [progress] (the scene confirms here).
  static const double tapAt = 0.66;

  static const double _size = AppSize.s36;

  /// The fingertip inside the glyph's box, from its top-start corner.
  static const Offset _tip = Offset(AppSize.s15, AppSize.s4);
  static const double _moveTo = 0.55;
  static const double _pressFrom = 0.58;
  static const double _releaseFrom = 0.72;
  static const double _releaseTo = 0.84;
  static const double _fadeFrom = 0.84;
  static const double _fadeInTo = 0.12;
  static const double _pressedScale = 0.82;
  static const double _alpha = 0.78;
  static const double _ring = AppSize.s44;
  static const double _ringWidth = AppSize.s2;
  static const double _glow = AppSize.s6;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final tip = Offset.lerp(
      from,
      to,
      progress.span(0, _moveTo, AppMotion.emphasizedDecelerate),
    )!;
    final press =
        progress.span(_pressFrom, tapAt) -
        progress.span(_releaseFrom, _releaseTo);
    final ring = progress.span(tapAt, 1, AppMotion.linear);
    final alpha =
        progress.span(0, _fadeInTo) * (1 - progress.span(_fadeFrom, 1));
    return PositionedDirectional(
      start: tip.dx - _ring / 2,
      top: tip.dy - _ring / 2,
      width: _ring,
      height: _ring,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (ring > 0)
            Positioned.fill(
              child: Transform.scale(
                scale: ring,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 1 - ring),
                      width: _ringWidth,
                    ),
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            start: _ring / 2 - _tip.dx,
            top: _ring / 2 - _tip.dy,
            child: Transform.scale(
              scale: 1 - (1 - _pressedScale) * press,
              alignment: AlignmentDirectional.topStart,
              child: Icon(
                Icons.touch_app_rounded,
                size: _size,
                color: AppColors.primaryText.withValues(alpha: _alpha * alpha),
                shadows: [
                  Shadow(
                    color: AppColors.white.withValues(alpha: alpha),
                    blurRadius: _glow,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
