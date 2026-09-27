import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../motion/spring_curve.dart';
import 'busy_overlay_layer.dart';

/// Holds the screen while a submit is in flight — sending a code, placing an
/// order, saving a form: a dim scrim fades over [child] and the white loader
/// disc springs in on it; taps and "back" wait until it is gone. Wrap the
/// page's `Scaffold`, so the app bar is covered too. [done] turns the dots
/// into a drawn check for the beat before the page moves on (announced as
/// [doneLabel]).
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
/// dots rest side by side.
class BusyOverlay extends StatefulWidget {
  const BusyOverlay({
    super.key,
    required this.busy,
    required this.child,
    this.done = false,
    this.label,
    this.doneLabel,
  });

  final bool busy;

  /// The work succeeded and the page is about to move on: the check.
  final bool done;

  /// Read out when the overlay appears (defaults to "Loading").
  final String? label;

  /// Read out when the check appears.
  final String? doneLabel;
  final Widget child;

  @override
  State<BusyOverlay> createState() => _BusyOverlayState();
}

class _BusyOverlayState extends State<BusyOverlay>
    with SingleTickerProviderStateMixin {
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

  /// Runs while the overlay has not been up [AppMotion.busyMinVisible] yet.
  Timer? _minimum;

  /// The scrim and the disc are on screen (coming, staying or going).
  bool _layerUp = false;
  bool _started = false;

  bool get _wanted => widget.busy || widget.done;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MotionGuard.reduced(context);
    _presence
      ..duration = reduced ? Duration.zero : AppMotion.slow
      ..reverseDuration = reduced ? Duration.zero : AppMotion.fast;
    // Mounted busy (a page that opens mid-submit): up from the first frame.
    if (!_started) {
      _started = true;
      if (_wanted) _show();
    }
  }

  @override
  void didUpdateWidget(BusyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wanted = oldWidget.busy || oldWidget.done;
    if (_wanted && !wanted) {
      _show();
    } else if (!_wanted && wanted && _minimum == null) {
      _leave();
    }
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
    super.dispose();
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
                label: widget.done
                    ? widget.doneLabel
                    : widget.label ?? 'core.loading'.tr(),
              ),
            ),
        ],
      ),
    );
  }
}
