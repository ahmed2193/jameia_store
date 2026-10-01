import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'on_screen_gate.dart';

/// Builds a loop's frame from its [loop] animation (0 → 1 per lap; 0 is the
/// resting pose). Hand [loop] to a painter's `repaint` or a `*Transition`,
/// so the loop repaints without rebuilding.
typedef AmbientLoopBuilder = Widget Function(
  BuildContext context,
  Animation<double> loop,
  Widget? child,
);

/// Builds one frame of a loop from its position [t] (0 = resting pose).
typedef AmbientLoopValueBuilder = Widget Function(
  BuildContext context,
  double t,
  Widget child,
);

/// AMBIENT LOOP (docs/motion §9.3 / §9.4 #22, D15, D19) — the one engine
/// behind every decorative loop (a float, a glow, a light sweep, the mark's
/// cape, a nudging arrow). It plays whole laps of [period], [rest] apart,
/// and only while it can be seen:
///
/// * [active], on screen ([OnScreenGate]: in view, app in the foreground)
///   and [MotionGuard.ambientAllowed] (not reduced, no screen reader, its
///   tab and route in front) — otherwise it holds its resting pose;
/// * for at most [budget] per appearance ([AppMotion.ambientBudget]; WCAG
///   2.2.2): a lap starts only when it ends inside the budget (the first
///   one always plays), and at most [maxLaps] of them. Then it rests,
///   drawing nothing, until it comes on screen again ([replay]).
///
/// A lap runs 0 → 1 through [curve]; with [reverse] it goes there AND back
/// within the one [period] (0 → 1 → 0), so every lap ends on the resting
/// pose. [phase] starts the first lap part-way, so neighbours keep apart.
/// A `null` [budget] is for a PROGRESS loop that must keep going while it
/// is seen (a loader's shimmer), never for decoration.
///
/// [exclusive] loops share one slot per route: while one plays, another
/// that comes on screen stays at rest until its next appearance (at most
/// one light sweep per screen).
class AmbientLoop extends StatefulWidget {
  const AmbientLoop({
    super.key,
    required this.period,
    required AmbientLoopBuilder this.builder,
    this.child,
    this.reverse = false,
    this.curve = AppMotion.linear,
    this.phase = 0,
    this.rest = Duration.zero,
    this.maxLaps,
    this.budget = AppMotion.ambientBudget,
    this.replay = true,
    this.exclusive = false,
    this.active = true,
  }) : valueBuilder = null;

  /// A loop whose frame is a small transform of [child] built from `t`,
  /// repainted in its own `RepaintBoundary`.
  const AmbientLoop.value({
    super.key,
    required this.period,
    required AmbientLoopValueBuilder this.valueBuilder,
    required Widget this.child,
    this.reverse = false,
    this.curve = AppMotion.linear,
    this.phase = 0,
    this.rest = Duration.zero,
    this.maxLaps,
    this.budget = AppMotion.ambientBudget,
    this.replay = true,
    this.exclusive = false,
    this.active = true,
  }) : builder = null;

  /// One lap (there and back, when [reverse]).
  final Duration period;
  final AmbientLoopBuilder? builder;
  final AmbientLoopValueBuilder? valueBuilder;
  final Widget? child;
  final bool reverse;
  final Curve curve;

  /// Where on the first lap (0–1) each appearance starts.
  final double phase;

  /// The still pause between two laps: a timer, no frames.
  final Duration rest;

  /// Most laps per appearance; `null` = as many as fit the [budget].
  final int? maxLaps;

  /// Longest run per appearance; `null` only for a progress loop.
  final Duration? budget;

  /// Plays again each time it comes back on screen; `false` = once for the
  /// widget's life (a counted hint).
  final bool replay;

  /// One playing loop per route (see the class doc).
  final bool exclusive;
  final bool active;

  @override
  State<AmbientLoop> createState() => _AmbientLoopState();
}

class _AmbientLoopState extends State<AmbientLoop>
    with SingleTickerProviderStateMixin, OnScreenGate<AmbientLoop> {
  /// The route slot [AmbientLoop.exclusive] loops share.
  static final Map<Object, _AmbientLoopState> _slots =
      <Object, _AmbientLoopState>{};
  static final Object _noRoute = Object();

  late final AnimationController _lap = AnimationController(
    vsync: this,
    duration: widget.period,
  )..addStatusListener(_lapStatus);
  late Animation<double> _loop = _drive();

  Timer? _rest;
  Timer? _deadline;
  Object _route = _noRoute;
  bool _allowed = false;
  bool _live = false;
  bool _played = false;

  /// This appearance is over (budget spent, laps done, or the slot taken).
  bool _done = false;

  /// Run time of this appearance so far, lap by lap.
  Duration _spent = Duration.zero;
  int _laps = 0;
  double _lapFrom = 0;

  Animation<double> _drive() =>
      _lap.drive(_LapTween(widget.curve, reverse: widget.reverse));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allowed = MotionGuard.ambientAllowed(context);
    final route = ModalRoute.of(context) ?? _noRoute;
    if (!identical(route, _route)) {
      _release();
      _route = route;
    }
    _sync();
  }

  @override
  void didUpdateWidget(covariant AmbientLoop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) _lap.duration = widget.period;
    if (oldWidget.curve != widget.curve ||
        oldWidget.reverse != widget.reverse) {
      _loop = _drive();
    }
    _sync();
  }

  @override
  void onScreenChanged() => _sync();

  /// Out of the tree (for good, or moving): the loop stops and the slot is
  /// free at once. A move (a GlobalKey reparent) starts a new appearance
  /// from [didChangeDependencies] (the element re-reads its dependencies
  /// there) under its new route — never a loop that runs without its slot.
  @override
  void deactivate() {
    if (_live) {
      // No value change here: its listeners are leaving the tree too.
      _live = false;
      _rest?.cancel();
      _rest = null;
      _deadline?.cancel();
      _deadline = null;
      _lap.stop();
    }
    _release();
    super.deactivate();
  }

  @override
  void dispose() {
    _rest?.cancel();
    _deadline?.cancel();
    _release();
    _lap.dispose();
    super.dispose();
  }

  bool get _wanted => widget.active && _allowed && onScreen;

  void _sync() {
    final live = _wanted;
    if (live == _live) return;
    _live = live;
    if (live) {
      _begin();
    } else {
      _halt();
    }
  }

  /// A new appearance: a fresh budget from the first lap.
  void _begin() {
    if (_played && !widget.replay) return;
    if (widget.exclusive && !_claim()) {
      _done = true;
      return;
    }
    _played = true;
    _done = false;
    _spent = Duration.zero;
    _laps = 0;
    final budget = widget.budget;
    _deadline?.cancel();
    _deadline = budget == null ? null : Timer(budget, _budgetSpent);
    _startLap(widget.phase.clamp(0.0, 1.0));
  }

  /// Out of sight: back to the resting pose, nothing scheduled.
  void _halt() {
    _rest?.cancel();
    _rest = null;
    _deadline?.cancel();
    _deadline = null;
    _release();
    _lap
      ..stop()
      ..value = 0;
  }

  void _startLap(double from) {
    _laps++;
    _lapFrom = from;
    _lap.forward(from: from);
  }

  void _lapStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_live || _done) return;
    _spent += widget.period * (1 - _lapFrom);
    final budget = widget.budget;
    final maxLaps = widget.maxLaps;
    final fits =
        budget == null || _spent + widget.rest + widget.period <= budget;
    if (!fits || (maxLaps != null && _laps >= maxLaps)) {
      _finish();
      return;
    }
    if (widget.rest <= Duration.zero) {
      _startLap(0);
      return;
    }
    _rest?.cancel();
    _rest = Timer(widget.rest, () {
      _rest = null;
      if (!mounted || !_live || _done) return;
      _spent += widget.rest;
      _startLap(0);
    });
  }

  /// The budget ran out with a lap longer than it still in flight: that
  /// lap lands on its end (the resting pose) quickly instead of freezing.
  void _budgetSpent() {
    _deadline = null;
    if (!mounted || _done) return;
    _rest?.cancel();
    _rest = null;
    if (!_lap.isAnimating) {
      _finish();
      return;
    }
    _done = true;
    final left = widget.period * (1 - _lap.value);
    _lap.animateTo(
      1,
      duration: left < AppMotion.medium ? left : AppMotion.medium,
    );
    _release();
  }

  /// This appearance is over: the lap already ended on the resting pose.
  void _finish() {
    _done = true;
    _rest?.cancel();
    _rest = null;
    _deadline?.cancel();
    _deadline = null;
    _release();
  }

  /// Takes the route's slot unless another loop still plays in it. A holder
  /// whose tab was hidden in this same frame (it has not heard yet) gives
  /// way: the tab coming on screen gets the sweep.
  bool _claim() {
    final holder = _slots[_route];
    if (holder != null &&
        !identical(holder, this) &&
        holder.mounted &&
        holder._live &&
        TickerMode.getValuesNotifier(holder.context).value.enabled) {
      return false;
    }
    _slots[_route] = this;
    return true;
  }

  void _release() {
    if (identical(_slots[_route], this)) _slots.remove(_route);
  }

  @override
  Widget build(BuildContext context) {
    final valueBuilder = widget.valueBuilder;
    if (valueBuilder == null) {
      return widget.builder!(context, _loop, widget.child);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _loop,
        child: widget.child,
        builder: (context, child) => valueBuilder(context, _loop.value, child!),
      ),
    );
  }
}

/// A lap's easing: [curve] over 0 → 1, or there and back (0 → 1 → 0) when
/// [reverse]. Not a `CurveTween`, which returns an end value of 1 as is: a
/// reversing lap must end on 0.
class _LapTween extends Animatable<double> {
  const _LapTween(this.curve, {required this.reverse});

  final Curve curve;
  final bool reverse;

  @override
  double transform(double t) {
    final leg = reverse ? 1 - (2 * t - 1).abs() : t;
    return curve.transform(math.min(1, math.max(0, leg)));
  }
}
