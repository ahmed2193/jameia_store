import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import '../motion/spring_curve.dart';
import '../responsive/app_size.dart';
import 'loader_check_painter.dart';

/// What a [LoaderDisc] turns into once the work is done: a brand-green badge
/// springs in (a touch past full size, then back) and a white tick draws
/// itself across it, short stroke then long. Reduced motion → the finished
/// badge at once.
class LoaderDoneMark extends StatefulWidget {
  const LoaderDoneMark({super.key});

  static const double size = AppSize.s44;

  /// The tick starts once the badge is this far into its spring.
  static const double _tickFrom = 0.35;

  @override
  State<LoaderDoneMark> createState() => _LoaderDoneMarkState();
}

class _LoaderDoneMarkState extends State<LoaderDoneMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _badge = _in.drive(
    CurveTween(curve: AppSprings.snappy),
  );
  late final Animation<double> _tick = _in.drive(
    CurveTween(
      curve: const Interval(
        LoaderDoneMark._tickFrom,
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
        dimension: LoaderDoneMark.size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: LoaderCheckPainter(
              progress: _tick,
              color: AppColors.brandForeground,
            ),
          ),
        ),
      ),
    );
  }
}
