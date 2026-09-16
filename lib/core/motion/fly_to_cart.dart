import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'motion.dart';

/// **core/motion/fly_to_cart.dart** — the KeeTa "add to cart" flight: when a
/// product is added, a shrinking thumbnail arcs from the tapped item along a
/// parabola into the cart badge, which then pops (the badge handles its own pop
/// via `PopScale` keyed on quantity).
///
/// Usage:
/// 1. Register the cart icon once (e.g. in the shell):
///    `FlyToCart.registerTarget(_cartIconKey);`  with that key on the icon.
/// 2. On add, from the product widget:
///    `FlyToCart.fly(context, sourceKey: _imgKey, thumbnail: Image(...));`
///
/// Reduced-motion → the flight is skipped entirely (the badge still pops when
/// the quantity changes), so accessibility users get the result without motion.
class FlyToCart {
  FlyToCart._();

  // Destination stack: index 0 is the base target (the shell cart badge, set via
  // [registerTarget]). Full-screen surfaces that carry their OWN cart icon (e.g.
  // the product-detail page, which occludes the shell tab bar) [pushTarget] a
  // temporary destination on top and [popTarget] it on dispose, so the flight
  // always lands on the visible icon.
  static final List<GlobalKey> _targets = [];

  static GlobalKey? get _targetKey => _targets.isEmpty ? null : _targets.last;

  /// Register the base cart badge/icon as the flight destination. Call once (e.g.
  /// in the shell); calling again replaces the base entry (e.g. on shell rebuild).
  static void registerTarget(GlobalKey key) {
    if (_targets.isEmpty) {
      _targets.add(key);
    } else {
      _targets[0] = key;
    }
  }

  /// Temporarily route flights to [key] — a full-screen surface's own cart icon.
  /// Pair with [popTarget] on dispose so the base target is restored.
  static void pushTarget(GlobalKey key) => _targets.add(key);

  /// Remove a temporary target added by [pushTarget].
  static void popTarget(GlobalKey key) => _targets.remove(key);

  /// Launch a flight from [sourceKey] to the registered cart target. No-op (but
  /// safe) if either endpoint can't be located or reduced-motion is on.
  static void fly(
    BuildContext context, {
    required GlobalKey sourceKey,
    required Widget thumbnail,
    double thumbSize = 56,
  }) {
    if (MotionGuard.reduced(context)) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _launch(overlay, _centerOfBox(sourceKey.currentContext?.findRenderObject()),
        thumbnail, thumbSize);
  }

  /// Same flight, but sourced from the render box of [sourceContext] itself — no
  /// GlobalKey needed. Used by the shared quick-add "+" controls so the flight
  /// plays from every add surface, not only the SKU sheet.
  static void flyFrom(
    BuildContext sourceContext, {
    required Widget thumbnail,
    double thumbSize = 56,
  }) {
    if (MotionGuard.reduced(sourceContext)) return;

    final overlay = Overlay.maybeOf(sourceContext, rootOverlay: true);
    if (overlay == null) return;

    _launch(overlay, _centerOfBox(sourceContext.findRenderObject()), thumbnail,
        thumbSize);
  }

  static void _launch(
    OverlayState overlay,
    Offset? src,
    Widget thumbnail,
    double thumbSize,
  ) {
    final dst = _centerOfBox(_targetKey?.currentContext?.findRenderObject());
    if (src == null || dst == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingThumb(
        start: src,
        end: dst,
        size: thumbSize,
        thumbnail: thumbnail,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static Offset? _centerOfBox(RenderObject? box) {
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

class _FlyingThumb extends StatefulWidget {
  const _FlyingThumb({
    required this.start,
    required this.end,
    required this.size,
    required this.thumbnail,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final double size;
  final Widget thumbnail;
  final VoidCallback onDone;

  @override
  State<_FlyingThumb> createState() => _FlyingThumbState();
}

class _FlyingThumbState extends State<_FlyingThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// Control point lifted above the midpoint → a gravity-like upward arc.
  late final Offset _ctrl = Offset(
    (widget.start.dx + widget.end.dx) / 2,
    widget.start.dy.clamp(0.0, widget.end.dy) - 120,
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _bezier(double t) {
    final mt = 1 - t;
    return widget.start * (mt * mt) +
        _ctrl * (2 * mt * t) +
        widget.end * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    // The [Positioned] MUST be the overlay theater's direct child (a Stack-like
    // render object), so [AnimatedBuilder] (which has no RenderObject of its own)
    // is the ROOT and the [RepaintBoundary] moves onto the static thumbnail
    // child. Wrapping the Positioned in a RepaintBoundary instead makes it a
    // child of RenderRepaintBoundary → "Incorrect use of ParentDataWidget".
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = AppMotion.signature.transform(_c.value);
        final pos = _bezier(t);
        // Shrink to ~30% and fade out over the last third of the flight.
        final scale = 1.0 - 0.7 * t;
        final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
        return Positioned(
          left: pos.dx - widget.size / 2,
          top: pos.dy - widget.size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          child: SizedBox.square(
            dimension: widget.size,
            child: widget.thumbnail,
          ),
        ),
      ),
    );
  }
}
