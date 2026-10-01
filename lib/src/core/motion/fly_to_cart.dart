import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';
import 'fly_to_cart_targets.dart';
import 'motion.dart';

export 'fly_to_cart_targets.dart';

/// **core/motion/fly_to_cart.dart** — the Hero "add to cart" flight
/// (docs/motion §9.4 #2): when a product is added, a shrinking thumbnail arcs
/// from the tapped item along a lifted bezier into the cart on screen over
/// [AppMotion.slow]. The cart's count badge (`CountBadge` with
/// `landsWithFlight`) waits for the landing ([landings]) and only then bumps
/// and rolls its number, so the count changes where the product arrives.
///
/// Usage:
/// 1. Register the cart icon once (e.g. in the shell):
///    `FlyToCart.registerTarget(_cartIconKey);`  with that key on the icon.
/// 2. On add, from the product widget (or through `CatalogCartGestures.add`):
///    `FlyToCart.flyFrom(context, thumbnail: Image(...));`
///
/// Where flights land lives in [FlyToCartTargets] (`fly_to_cart_targets.dart`);
/// the static target methods here are its app-wide front door. A flight
/// lands on the topmost destination that is on screen (mounted, laid out and
/// not under a covering route); with none on screen, at [maxFlights] flights
/// already in the air, or under reduced motion there is no flight — the add
/// still happens and the badge changes at once.
class FlyToCart {
  FlyToCart._();

  /// The thumbnail's side when the caller does not pick one.
  static const double defaultThumbSize = AppSize.s56;

  /// At most this many thumbnails are in the air together; a faster tap
  /// adds without a flight.
  static const int maxFlights = 3;

  /// The app's one destination stack (see [FlyToCartTargets]).
  static final FlyToCartTargets _targets = FlyToCartTargets();

  static int _airborne = 0;
  static final ValueNotifier<int> _landings = ValueNotifier<int>(0);
  static final ValueNotifier<bool> _inFlight = ValueNotifier<bool>(false);

  /// How many thumbnails are in the air right now.
  static int get airborne => _airborne;

  /// Whether a thumbnail is in the air: a reaction that must not compete
  /// with the flight (the assistant buddy's hop) waits until it is `false`.
  static ValueListenable<bool> get inFlight => _inFlight;

  static void _setAirborne(int count) {
    _airborne = count;
    _inFlight.value = count > 0;
  }

  /// Ticks once every time a thumbnail lands (or is dropped mid-air): a
  /// badge waiting for its flight updates on it.
  static ValueListenable<int> get landings => _landings;

  /// Where a flight launched now would land (the top of the target stack).
  @visibleForTesting
  static GlobalKey? get debugTarget => _targets.top;

  /// Register the base cart badge/icon as the flight destination. Call once (e.g.
  /// in the shell); calling again replaces the base entry (e.g. on shell rebuild).
  static void registerTarget(GlobalKey key) => _targets.register(key);

  /// Temporarily route flights to [key] — a full-screen surface's own cart icon.
  /// Pair with [popTarget] on dispose so the base target is restored.
  static void pushTarget(GlobalKey key) => _targets.push(key);

  /// Remove a temporary target added by [pushTarget].
  static void popTarget(GlobalKey key) => _targets.pop(key);

  /// Launch a flight from [sourceKey] to the cart on screen. Returns whether
  /// a thumbnail took off (false: reduced motion, no source or destination
  /// on screen, or [maxFlights] already in the air).
  static bool fly(
    BuildContext context, {
    required GlobalKey sourceKey,
    required Widget thumbnail,
    double thumbSize = defaultThumbSize,
  }) {
    if (MotionGuard.reduced(context)) return false;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return false;

    return _launch(
      overlay,
      _centerOfBox(sourceKey.currentContext?.findRenderObject()),
      thumbnail,
      thumbSize,
    );
  }

  /// Same flight, but sourced from the render box of [sourceContext] itself — no
  /// GlobalKey needed. Used by the shared quick-add "+" controls so the flight
  /// plays from every add surface, not only the SKU sheet.
  static bool flyFrom(
    BuildContext sourceContext, {
    required Widget thumbnail,
    double thumbSize = defaultThumbSize,
  }) {
    if (MotionGuard.reduced(sourceContext)) return false;

    final overlay = Overlay.maybeOf(sourceContext, rootOverlay: true);
    if (overlay == null) return false;

    return _launch(
      overlay,
      _centerOfBox(sourceContext.findRenderObject()),
      thumbnail,
      thumbSize,
    );
  }

  static bool _launch(
    OverlayState overlay,
    Offset? src,
    Widget thumbnail,
    double thumbSize,
  ) {
    if (_airborne >= maxFlights) return false;
    final dst = _destination();
    if (src == null || dst == null) return false;

    _setAirborne(_airborne + 1);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingThumb(
        start: src,
        end: dst,
        size: thumbSize,
        thumbnail: thumbnail,
        onLanded: () {
          // Removed and released (leak_tracker): the entry is done.
          if (entry.mounted) {
            entry
              ..remove()
              ..dispose();
          }
          _setAirborne(_airborne - 1);
          _landings.value++;
        },
        onDropped: () {
          _airborne--;
          // Mid tree teardown: tell the waiting badges once it is over.
          scheduleMicrotask(() {
            _inFlight.value = _airborne > 0;
            _landings.value++;
          });
        },
      ),
    );
    overlay.insert(entry);
    return true;
  }

  /// The centre of the topmost destination on screen: mounted, laid out and
  /// not in a route covered by another (its tickers run), or null.
  static Offset? _destination() {
    for (final key in _targets.fromTop) {
      final context = key.currentContext;
      if (context == null || !context.mounted) continue;
      if (!TickerMode.getValuesNotifier(context).value.enabled) continue;
      final center = _centerOfBox(context.findRenderObject());
      if (center != null) return center;
    }
    return null;
  }

  static Offset? _centerOfBox(RenderObject? box) {
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

class _FlyingThumb extends StatefulWidget {
  const _FlyingThumb({
    required this.start,
    required this.end,
    required this.size,
    required this.thumbnail,
    required this.onLanded,
    required this.onDropped,
  });

  final Offset start;
  final Offset end;
  final double size;
  final Widget thumbnail;

  /// The thumbnail reached the cart (called once, or [onDropped] instead).
  final VoidCallback onLanded;

  /// The flight was torn down mid-air (its overlay went away) — called from
  /// `dispose`, so it must not rebuild anything synchronously.
  final VoidCallback onDropped;

  @override
  State<_FlyingThumb> createState() => _FlyingThumbState();
}

class _FlyingThumbState extends State<_FlyingThumb>
    with SingleTickerProviderStateMixin {
  /// How far above the higher end the arc's control point is lifted.
  static const double _arcLift = AppSize.s120;

  /// How much the thumbnail shrinks over the flight (to 30 % at the land).
  static const double _shrinkShare = 0.7;

  /// Where the fade-out starts (the last third of the flight).
  static const double _fadeFrom = 0.7;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// The flight's progress along the path, eased once.
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: AppMotion.signature,
  );

  /// Fully there until [_fadeFrom], then out by the landing.
  late final Animation<double> _opacity = _t.drive(
    Tween<double>(
      begin: 1,
      end: 0,
    ).chain(CurveTween(curve: const Interval(_fadeFrom, 1))),
  );

  /// Control point lifted above the midpoint → a gravity-like upward arc.
  late final Offset _ctrl = Offset(
    (widget.start.dx + widget.end.dx) / 2,
    widget.start.dy.clamp(0.0, widget.end.dy) - _arcLift,
  );

  bool _done = false;

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onLanded();
  }

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    // Torn down mid-air: still count it as landed, so no badge waits.
    if (!_done) {
      _done = true;
      widget.onDropped();
    }
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
    // The fade is a [FadeTransition] on the static child, never an `Opacity`
    // rebuilt per frame (docs/motion PB-21).
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) {
        final t = _t.value;
        final pos = _bezier(t);
        // Shrink to ~30% over the flight.
        final scale = 1.0 - _shrinkShare * t;
        return Positioned(
          left: pos.dx - widget.size / 2,
          top: pos.dy - widget.size / 2,
          child: IgnorePointer(
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: FadeTransition(
        opacity: _opacity,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r4),
            child: SizedBox.square(
              dimension: widget.size,
              child: widget.thumbnail,
            ),
          ),
        ),
      ),
    );
  }
}
