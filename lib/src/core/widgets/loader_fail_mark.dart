import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import 'loader_cross_painter.dart';
import 'loader_done_mark.dart';

/// What a [LoaderDisc] turns into when the work could not finish — the
/// partner of [LoaderDoneMark] (docs/motion B3-05): a red badge settles in
/// (the calm spring: no celebratory overshoot) and a white × draws itself,
/// one stroke then the other. The words come after, in the snack bar.
/// Reduced motion → the finished badge at once.
class LoaderFailMark extends StatefulWidget {
  const LoaderFailMark({super.key});

  static const double size = LoaderDoneMark.size;

  /// The × starts once the badge is this far into its spring.
  static const double _crossFrom = 0.35;

  @override
  State<LoaderFailMark> createState() => _LoaderFailMarkState();
}

class _LoaderFailMarkState extends State<LoaderFailMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _badge = _in.drive(
    CurveTween(curve: AppSprings.calm),
  );
  late final Animation<double> _cross = _in.drive(
    CurveTween(
      curve: const Interval(
        LoaderFailMark._crossFrom,
        1,
        curve: AppMotion.emphasizedDecelerate,
      ),
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MotionGuard.reduced(context)) {
      _in.value = 1;
    } else {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _badge,
      child: SizedBox.square(
        dimension: LoaderFailMark.size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: LoaderCrossPainter(
              progress: _cross,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
