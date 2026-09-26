import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';

/// Rounded track filled to [current] / [target] (clamped to 0..1). The fill
/// grows from empty over [AppMotion.slow] the first time it is shown and
/// glides to a new ratio when the balance changes. It slides in from the
/// start edge inside the clipped track (a paint-only translation, no
/// relayout per frame), so it mirrors under RTL. Reduced motion → the final
/// fill at once.
class RewardProgressBar extends StatelessWidget {
  const RewardProgressBar({
    super.key,
    required this.current,
    required this.target,
    required this.height,
    required this.trackColor,
    required this.fillColors,
  });

  final int current;
  final int target;
  final double height;
  final Color trackColor;

  /// One colour for a flat fill, more for a start → end gradient.
  final List<Color> fillColors;

  double get ratio =>
      target <= 0 ? 1 : (current / target).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    final towardsEnd = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final radius = BorderRadius.circular(AppRadius.pill);
    final fill = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: fillColors.length == 1 ? fillColors.first : null,
        gradient: fillColors.length > 1
            ? LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: fillColors,
              )
            : null,
      ),
      child: const SizedBox.expand(),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: trackColor,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: MotionGuard.duration(context, AppMotion.slow),
              curve: AppMotion.emphasizedDecelerate,
              child: fill,
              builder: (context, value, child) => FractionalTranslation(
                translation: Offset((value - 1) * towardsEnd, 0),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
