import 'package:flutter/widgets.dart';

import 'motion.dart';

/// "This changed, and here is what it means": when [value] changes (never on
/// mount) one wash of [color] rises over the first quarter of
/// [AppMotion.breathe] and fades over the rest, under the child ([over]
/// false: a mint wash behind a cheaper total) or over it ([over] true: a red
/// "no" on a refused tap). [when] filters which changes deserve a wash (a
/// drop, not a rise).
///
/// The wash is a colour, never a layout change: the child keeps one fixed
/// slot of an always-built `Stack` and the layer slot holds nothing at rest,
/// so a flash never remounts the child (a counting or rolling number inside
/// keeps its state). While it plays the layer sits in its own
/// [RepaintBoundary] and ignores touches and semantics; it is dropped when
/// the run ends.
///
/// Reduced motion → never plays (the colour of the child is the message),
/// unless [reducedOnly]: then it plays only there, as the stand-in for a
/// movement the owner drops.
/// Inside a muted `TickerMode` (a covered page) a change waits and plays when
/// the page is revealed.
class TintFlash<T> extends StatefulWidget {
  const TintFlash({
    super.key,
    required this.value,
    required this.color,
    required this.child,
    this.when,
    this.over = false,
    this.peakAlpha = defaultPeakAlpha,
    this.borderRadius = BorderRadius.zero,
    this.inflate = 0,
    this.duration = AppMotion.breathe,
    this.reducedOnly = false,
  });

  static const double defaultPeakAlpha = 1;

  final T value;

  /// The wash colour at its peak (times [peakAlpha]).
  final Color color;
  final Widget child;

  /// Which changes wash (`previous`, `next`); `null` = every change.
  final bool Function(T previous, T next)? when;

  /// The layer paints over the child instead of under it.
  final bool over;

  /// The layer's opacity at the peak of the wash.
  final double peakAlpha;
  final BorderRadius borderRadius;

  /// How far the wash reaches past the child's box on every side.
  final double inflate;

  /// One whole wash (rise + fade).
  final Duration duration;

  /// The wash stands in for motion: it plays ONLY under reduced motion (not
  /// when animations are off), where the owner shows no movement — a badge
  /// that tints instead of bumping (docs/motion §9.4 #2).
  final bool reducedOnly;

  @override
  State<TintFlash<T>> createState() => _TintFlashState<T>();
}

class _TintFlashState<T> extends State<TintFlash<T>>
    with SingleTickerProviderStateMixin {
  static const double _riseWeight = 25;
  static const double _fallWeight = 75;
  static const Key _childKey = ValueKey<String>('tint-flash-child');
  static const Key _layerKey = ValueKey<String>('tint-flash-layer');

  /// Built on the first wash: most flashes never play.
  AnimationController? _controller;
  Animation<double>? _opacity;
  double? _opacityPeak;
  bool _playing = false;

  AnimationController _ensureController() {
    final existing = _controller;
    if (existing != null) return existing;
    return _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener(_onStatus);
  }

  Animation<double> _opacityFor(AnimationController controller) {
    final peak = widget.peakAlpha;
    final cached = _opacity;
    if (cached != null && _opacityPeak == peak) return cached;
    _opacityPeak = peak;
    return _opacity = controller.drive(
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0,
            end: peak,
          ).chain(CurveTween(curve: AppMotion.signature)),
          weight: _riseWeight,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: peak,
            end: 0,
          ).chain(CurveTween(curve: AppMotion.exit)),
          weight: _fallWeight,
        ),
      ]),
    );
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _playing = false);
  }

  /// A wash asked for while the tickers are muted (a covered page): it
  /// starts when they run again, so the whole wash is seen.
  bool _pending = false;

  void _play() {
    _pending = false;
    final reduced = MotionGuard.reduced(context);
    final plays = widget.reducedOnly
        ? reduced && !MotionGuard.off(context)
        : !reduced;
    if (!plays) return;
    if (!TickerMode.valuesOf(context).enabled) {
      _pending = true;
      return;
    }
    final controller = _ensureController();
    _opacityFor(controller);
    _playing = true;
    controller.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pending) _play();
  }

  @override
  void didUpdateWidget(TintFlash<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    final washes = widget.when?.call(oldWidget.value, widget.value) ?? true;
    if (washes) _play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inflate = -widget.inflate;
    final controller = _controller;
    final layer = Positioned(
      key: _layerKey,
      left: inflate,
      top: inflate,
      right: inflate,
      bottom: inflate,
      child: _playing && controller != null
          ? IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: FadeTransition(
                    opacity: _opacityFor(controller),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: widget.borderRadius,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: widget.over ? [child, layer] : [layer, child],
    );
  }
}
