import 'package:flutter/material.dart';

import '../motion/motion.dart';
import 'light_sweep_band.dart';

/// The fill of a pill that says "you can go now": [idleColor] while not
/// [ready], [readyColor] when it is. When [ready] turns true after the first
/// build, the ready colour wipes in from the start edge (the right in RTL)
/// over the first 57 % of [AppMotion.drawOn] and one light band crosses the
/// pill over its last 57 %; it lands static. Turning not-ready shows the idle
/// colour at once. At mount the fill is static.
///
/// The child keeps one fixed slot of an always-built `Stack` (fill, child,
/// sheen), so the wipe never remounts it. While the wipe plays, the fill and
/// the band paint in their own layers, clipped to [borderRadius]; at rest
/// there is no clip and no band.
///
/// Reduced motion → the colour changes at once. Inside a muted `TickerMode`
/// (a covered page) the wipe waits and plays when the page is revealed.
class ReadyWipe extends StatefulWidget {
  const ReadyWipe({
    super.key,
    required this.ready,
    required this.readyColor,
    required this.idleColor,
    required this.borderRadius,
    required this.child,
  });

  final bool ready;
  final Color readyColor;
  final Color idleColor;
  final BorderRadius borderRadius;
  final Widget child;

  /// The share of the run the fill takes, and where the band starts.
  static const double fillEnd = 0.57;
  static const double sheenStart = 0.43;

  @override
  State<ReadyWipe> createState() => _ReadyWipeState();
}

class _ReadyWipeState extends State<ReadyWipe>
    with SingleTickerProviderStateMixin {
  static const Key _fillKey = ValueKey<String>('ready-wipe-fill');
  static const Key _childKey = ValueKey<String>('ready-wipe-child');
  static const Key _sheenKey = ValueKey<String>('ready-wipe-sheen');

  /// Built on the first wipe.
  AnimationController? _controller;
  Animation<double>? _fill;
  Animation<double>? _sheen;
  bool _playing = false;

  AnimationController _ensureController() {
    final existing = _controller;
    if (existing != null) return existing;
    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.drawOn,
    )..addStatusListener(_onStatus);
    _fill = controller.drive(
      CurveTween(
        curve: const Interval(
          0,
          ReadyWipe.fillEnd,
          curve: AppMotion.emphasizedDecelerate,
        ),
      ),
    );
    _sheen = controller.drive(
      CurveTween(
        curve: const Interval(
          ReadyWipe.sheenStart,
          1,
          curve: AppMotion.machEaseInOut,
        ),
      ),
    );
    return _controller = controller;
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _playing = false);
  }

  /// A wipe asked for while the tickers are muted (a covered page): the
  /// pill stays idle-coloured and wipes when they run again, so the whole
  /// moment is seen.
  bool _pending = false;

  void _play() {
    _pending = false;
    if (MotionGuard.reduced(context)) return;
    if (!TickerMode.valuesOf(context).enabled) {
      _pending = true;
      return;
    }
    _playing = true;
    _ensureController().forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pending) _play();
  }

  @override
  void didUpdateWidget(ReadyWipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ready == widget.ready) return;
    if (!widget.ready) {
      // Not ready any more: the idle colour at once.
      _controller?.stop();
      _playing = false;
      _pending = false;
      return;
    }
    _play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = _fill;
    final sheen = _sheen;
    final playing = _playing && fill != null && sheen != null;
    final radius = widget.borderRadius;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          key: _fillKey,
          child: playing
              ? RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: ColoredBox(
                      color: widget.idleColor,
                      child: AnimatedBuilder(
                        animation: fill,
                        builder: (context, child) => FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: fill.value,
                          heightFactor: 1,
                          child: child,
                        ),
                        child: ColoredBox(color: widget.readyColor),
                      ),
                    ),
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.ready && !_pending
                        ? widget.readyColor
                        : widget.idleColor,
                    borderRadius: radius,
                  ),
                ),
        ),
        KeyedSubtree(key: _childKey, child: widget.child),
        Positioned.fill(
          key: _sheenKey,
          child: playing
              ? LightSweepBand(sweep: sheen, borderRadius: radius)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
