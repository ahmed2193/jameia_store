import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/entrance_arrival.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// The little hand beside the greeting: it waves hello once, as the greeting
/// lands, and again every time [trigger] ticks (a tap on the greeting).
/// Rests still under reduced motion, and reads to nobody — the greeting says
/// hello in words.
class HomeWavingHand extends StatefulWidget {
  const HomeWavingHand({super.key, required this.trigger});

  final Listenable trigger;

  @override
  State<HomeWavingHand> createState() => _HomeWavingHandState();
}

class _HomeWavingHandState extends State<HomeWavingHand>
    with SingleTickerProviderStateMixin {
  static const Duration _waveTime = Duration(milliseconds: 1200);
  static const double _glyph = AppSize.s20;

  /// The wrist the hand turns around.
  static const Alignment _wrist = Alignment(-0.3, 0.8);

  /// Hi, hi, hi — three swings that die away, back to rest.
  static final Animatable<double> _swings = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 0.3), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.3, end: -0.14), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -0.14, end: 0.3), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.3, end: -0.07), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -0.07, end: 0.18), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.18, end: 0), weight: 1),
  ]).chain(CurveTween(curve: AppMotion.machEaseInOut));

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _waveTime,
  );

  Animation<double>? _arrival;
  bool _greeted = false;

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_wave);
  }

  @override
  void didUpdateWidget(HomeWavingHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_wave);
      widget.trigger.addListener(_wave);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arrival = EntranceArrival.of(context);
    if (arrival == _arrival) return;
    _arrival?.removeStatusListener(_landed);
    _arrival = arrival..addStatusListener(_landed);
    _landed(arrival.status);
  }

  @override
  void dispose() {
    _arrival?.removeStatusListener(_landed);
    widget.trigger.removeListener(_wave);
    _controller.dispose();
    super.dispose();
  }

  /// Says hello the first time the greeting has fully landed.
  void _landed(AnimationStatus status) {
    if (_greeted || status != AnimationStatus.completed) return;
    _greeted = true;
    _wave();
  }

  void _wave() {
    if (!mounted || MotionGuard.reduced(context)) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          child: const HeroIcon(
            HeroIcons.wave,
            size: _glyph,
            color: AppColors.accent3,
          ),
          builder: (context, child) => Transform.rotate(
            angle: _swings.transform(_controller.value),
            alignment: _wrist,
            child: child,
          ),
        ),
      ),
    );
  }
}
