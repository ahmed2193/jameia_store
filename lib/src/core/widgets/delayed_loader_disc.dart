import 'dart:async';

import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import 'loader_disc.dart';

/// [LoaderDisc] for a block load: it waits [AppMotion.loaderDelay] — a load
/// that answers at once never flashes a loader, also under reduced motion —
/// then fades in and springs up from a smaller disc. Reduced motion → after
/// the same wait, the disc at once, still.
///
/// The wait is a timer, not an invisible stretch of the animation: nothing
/// ticks before the disc shows.
class DelayedLoaderDisc extends StatefulWidget {
  const DelayedLoaderDisc({super.key});

  static const double _scaleFrom = 0.7;

  @override
  State<DelayedLoaderDisc> createState() => _DelayedLoaderDiscState();
}

class _DelayedLoaderDiscState extends State<DelayedLoaderDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _opacity = _in.drive(
    CurveTween(curve: AppMotion.signature),
  );
  late final Animation<double> _scale = _in.drive(
    Tween<double>(
      begin: DelayedLoaderDisc._scaleFrom,
      end: 1,
    ).chain(CurveTween(curve: AppSprings.snappy)),
  );
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    _wait = Timer(AppMotion.loaderDelay, _show);
  }

  void _show() {
    if (!mounted) return;
    if (MotionGuard.reduced(context)) {
      _in.value = 1;
    } else {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
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
