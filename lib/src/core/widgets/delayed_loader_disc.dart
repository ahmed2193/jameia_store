import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../motion/spring_curve.dart';
import 'loader_disc.dart';

/// [LoaderDisc] for a block load: it waits [AppMotion.loaderDelay] — a load
/// that answers at once never flashes a loader — then fades in and springs
/// up from a smaller disc. Reduced motion → the disc at once, still.
class DelayedLoaderDisc extends StatefulWidget {
  const DelayedLoaderDisc({super.key});

  static const double _scaleFrom = 0.7;

  @override
  State<DelayedLoaderDisc> createState() => _DelayedLoaderDiscState();
}

class _DelayedLoaderDiscState extends State<DelayedLoaderDisc>
    with SingleTickerProviderStateMixin {
  static final Duration _total = AppMotion.loaderDelay + AppMotion.slow;
  static final double _waitShare =
      AppMotion.loaderDelay.inMicroseconds / _total.inMicroseconds;

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final Animation<double> _opacity = _in.drive(
    CurveTween(curve: Interval(_waitShare, 1, curve: AppMotion.signature)),
  );
  late final Animation<double> _scale = _in.drive(
    Tween<double>(begin: DelayedLoaderDisc._scaleFrom, end: 1).chain(
      CurveTween(curve: Interval(_waitShare, 1, curve: AppSprings.snappy)),
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
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: const LoaderDisc()),
    );
  }
}
