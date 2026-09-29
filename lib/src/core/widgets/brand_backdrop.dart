import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../motion/on_screen_gate.dart';
import 'brand_backdrop_base_painter.dart';
import 'brand_backdrop_clock.dart';
import 'brand_backdrop_painter.dart';
import 'brand_backdrop_ring.dart';

/// The brand's living backdrop: the Hero green with a spread of groceries
/// laid around the logo, turning slowly like a table under a camera — the
/// app's take on a food-photo header. Fills its box; the spread frames
/// [band] (the part of the header left uncovered, in this box's
/// coordinates) and turns about its centre.
///
/// The spread fades and settles in on mount when [reveal] is set (the first
/// page of a flow; the next page shows it at once). It turns while
/// [animate] — hosts stop it while the keyboard is up — for at most
/// [AppMotion.ambientBudget] each time it starts again (D19), and only
/// while it can be seen: on screen, in the foreground, its route in front
/// (`TickerMode`), no screen reader, never under reduced motion.
///
/// Two layers (BX-02): the green and the light are painted once in a
/// `RepaintBoundary` of their own; one ticker repaints only the turning
/// spread above them (no rebuilds). The turn is shared
/// ([BrandBackdropClock]) so pages hand the spread on without a jump.
class BrandBackdrop extends StatefulWidget {
  const BrandBackdrop({
    super.key,
    required this.band,
    this.animate = true,
    this.reveal = true,
  });

  final Rect band;
  final bool animate;
  final bool reveal;

  /// How long the spread takes to fade and settle in.
  static const Duration revealDuration = Duration(milliseconds: 900);

  @override
  State<BrandBackdrop> createState() => _BrandBackdropState();
}

class _BrandBackdropState extends State<BrandBackdrop>
    with TickerProviderStateMixin, OnScreenGate<BrandBackdrop> {
  late final Ticker _ticker = createTicker(_onTick);
  late final ValueNotifier<Duration> _time = ValueNotifier<Duration>(
    BrandBackdropClock.elapsed,
  );
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: BrandBackdrop.revealDuration,
    value: widget.reveal ? 0 : 1,
  );
  late final CurvedAnimation _revealCurve = CurvedAnimation(
    parent: _reveal,
    curve: AppMotion.signature,
  );
  final BrandBackdropRing _ring = BrandBackdropRing();
  bool _reduced = false;
  bool _allowed = false;

  /// Ends this run of the turn once the ambient budget is spent.
  Timer? _budget;
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionGuard.reduced(context);
    _allowed = MotionGuard.ambientAllowed(context);
    if (_reduced) {
      _reveal.value = 1;
    } else if (!_reveal.isCompleted && !_reveal.isAnimating) {
      _reveal.forward();
    }
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant BrandBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncTicker();
  }

  @override
  void onScreenChanged() => _syncTicker();

  /// A new run (the backdrop comes on screen, the keyboard goes down)
  /// turns for one ambient budget, then holds still until the next one.
  void _syncTicker() {
    final run = widget.animate && _allowed && onScreen;
    if (run == _running) return;
    _running = run;
    _budget?.cancel();
    if (run) {
      _budget = Timer(AppMotion.ambientBudget, () {
        _budget = null;
        if (_ticker.isActive) _ticker.stop();
      });
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration _) {
    _time.value = BrandBackdropClock.advance(
      SchedulerBinding.instance.currentFrameTimeStamp,
    );
  }

  @override
  void dispose() {
    _budget?.cancel();
    _ticker.dispose();
    _revealCurve.dispose();
    _reveal.dispose();
    _time.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: BrandBackdropBasePainter(band: widget.band),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: BrandBackdropPainter(
              ring: _ring,
              band: widget.band,
              time: _time,
              reveal: _revealCurve,
            ),
          ),
        ),
      ],
    );
  }
}
