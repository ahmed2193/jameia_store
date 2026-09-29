import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import 'busy_overlay_layer.dart';

/// Holds the screen while a submit is in flight — sending a code, placing an
/// order, saving a form: a dim scrim fades over [child] and the white loader
/// disc springs in on it; taps and "back" wait until it is gone. Wrap the
/// page's `Scaffold`, so the app bar is covered too. [done] turns the dots
/// into a drawn check for the beat before the page moves on (announced as
/// [doneLabel]).
///
/// [failed] turning true while the overlay is up (the submit came back
/// refused or unreached) turns the dots into a drawn × instead
/// (docs/motion B3-05), holds it for the mark's draw plus
/// [AppMotion.successHold] (announced as [failLabel]), then the overlay
/// leaves and the snack bar the page shows for the failure is what stays.
///
/// It shows at once — a submit wants an answer to the tap — and, once
/// shown, stays at least [AppMotion.busyMinVisible], so a fast reply reads
/// as a beat, not a flicker. The layer is stacked over [child] only while
/// it is up (an idle overlay adds nothing to the tree); a shell tab that is
/// not on screen ([Visibility.of]) shows nothing and never holds "back".
/// The pill that fired the submit keeps its label; the disc is the one
/// loader on screen.
///
/// Reduced motion: the scrim and the disc come and go without motion, the
/// dots rest side by side, the marks appear whole (the × still holds for
/// [AppMotion.successHold]).
class BusyOverlay extends StatefulWidget {
  const BusyOverlay({
    super.key,
    required this.busy,
    required this.child,
    this.done = false,
    this.failed = false,
    this.label,
    this.doneLabel,
    this.failLabel,
  });

  final bool busy;

  /// The work succeeded and the page is about to move on: the check.
  final bool done;

  /// The work could not finish. Only a change to `true` while the overlay
  /// is up plays the × (a failure left over from before is not replayed).
  final bool failed;

  /// Read out when the overlay appears (defaults to "Loading").
  final String? label;

  /// Read out when the check appears.
  final String? doneLabel;

  /// Read out when the × appears (defaults to "Couldn't finish").
  final String? failLabel;
  final Widget child;

  @override
  State<BusyOverlay> createState() => _BusyOverlayState();
}

class _BusyOverlayState extends State<BusyOverlay>
    with TickerProviderStateMixin {
  /// The disc follows the scrim in once it is this far along.
  static const double _discFrom = 0.2;

  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    reverseDuration: AppMotion.fast,
  );
  late final CurvedAnimation _scrim = CurvedAnimation(
    parent: _presence,
    curve: AppMotion.signature,
    reverseCurve: AppMotion.exit,
  );
  late final CurvedAnimation _disc = CurvedAnimation(
    parent: _presence,
    curve: Interval(_discFrom, 1, curve: AppSprings.snappy),
    reverseCurve: AppMotion.exit,
  );

  /// The × on screen: its draw, then the hold. A frame-driven clock (not a
  /// timer) so the beat also runs out under a test's settle.
  late final AnimationController _failBeat = AnimationController(
    vsync: this,
    duration: AppMotion.slow + AppMotion.successHold,
  );

  /// Runs while the overlay has not been up [AppMotion.busyMinVisible] yet.
  Timer? _minimum;

  /// The scrim and the disc are on screen (coming, staying or going).
  bool _layerUp = false;
  bool _started = false;

  /// The × is showing (its beat has not run out yet).
  bool _failing = false;

  bool get _wanted => widget.busy || widget.done || _failing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MotionGuard.reduced(context);
    _presence
      ..duration = reduced ? Duration.zero : AppMotion.slow
      ..reverseDuration = reduced ? Duration.zero : AppMotion.fast;
    _failBeat.duration = reduced
        ? AppMotion.successHold
        : AppMotion.slow + AppMotion.successHold;
    // Mounted busy (a page that opens mid-submit): up from the first frame.
    if (!_started) {
      _started = true;
      if (_wanted) _show();
    }
  }

  @override
  void didUpdateWidget(BusyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wanted = oldWidget.busy || oldWidget.done || _failing;
    if (widget.busy && !oldWidget.busy) _stopFailing();
    if (widget.failed && !oldWidget.failed && !widget.done && _layerUp) {
      _startFailing();
    }
    if (_wanted && !wanted) {
      _show();
    } else if (!_wanted && wanted && _minimum == null) {
      _leave();
    }
  }

  /// Called before a build (new flags), so no setState.
  void _startFailing() {
    _failing = true;
    unawaited(
      _failBeat
          .forward(from: 0)
          .orCancel
          .then(
            (_) => _onFailShown(),
            onError: (Object _) {}, // disposed mid-beat
          ),
    );
  }

  void _stopFailing() {
    if (!_failing) return;
    _failing = false;
    _failBeat.stop();
  }

  void _onFailShown() {
    if (!mounted || !_failing) return;
    setState(() => _failing = false);
    if (!_wanted && _minimum == null) _leave();
  }

  /// Called before a build (mount / new flags), so no setState.
  void _show() {
    if (!_layerUp) {
      _layerUp = true;
      _minimum?.cancel();
      _minimum = Timer(AppMotion.busyMinVisible, _onMinimumShown);
    }
    unawaited(_presence.forward());
  }

  void _onMinimumShown() {
    _minimum = null;
    if (mounted && !_wanted) _leave();
  }

  void _leave() {
    _presence.reverse().whenCompleteOrCancel(() {
      if (!mounted || _wanted || !_presence.isDismissed) return;
      setState(() => _layerUp = false);
    });
  }

  @override
  void dispose() {
    _minimum?.cancel();
    _scrim.dispose();
    _disc.dispose();
    _presence.dispose();
    _failBeat.dispose();
    super.dispose();
  }

  String? get _label {
    if (widget.done) return widget.doneLabel;
    if (_failing) return widget.failLabel ?? 'core.action_failed'.tr();
    return widget.label ?? 'core.loading'.tr();
  }

  @override
  Widget build(BuildContext context) {
    // A shell tab stays mounted (and busy) while another tab is on screen:
    // it must neither cover that tab nor hold its "back".
    final onScreen = Visibility.of(context);
    return PopScope(
      canPop: !(_wanted && onScreen),
      // The child keeps its place (index 0) whether or not the layer is up,
      // so the page is never re-created under it.
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_layerUp && onScreen)
            Positioned.fill(
              child: BusyOverlayLayer(
                scrim: _scrim,
                disc: _disc,
                done: widget.done,
                failed: _failing,
                label: _label,
              ),
            ),
        ],
      ),
    );
  }
}
