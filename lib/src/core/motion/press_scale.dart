import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;

import 'haptics.dart';
import 'motion.dart';

/// THE press feedback (docs/motion §9.4 #1, backlog B1-16) — every tappable
/// card, tile, row, chip, pill and button answers a touch the same way:
/// it shrinks to [pressedScale] ([AppMotion.pressedScale] 0.97; icon
/// buttons under 48 dp pass [AppMotion.pressedScaleSmall] 0.92) on
/// touch-down over [AppMotion.microPop] and settles back on release over
/// [AppMotion.fast], both with the signature ease-out. Reduced motion → no
/// scale (a row's press tint, if it has one, stays).
///
/// Supply [onTap] here (the wrapper handles the gesture) OR leave [onTap]
/// null to animate a child that owns its own gesture (an `InkWell` whose
/// highlight is the row's press tint).
///
/// No stacked presses: a finger dips only the INNERMOST press under it. A
/// "+" inside a product card, an action pill inside an order card, an icon
/// button inside a row press themselves; the card / row around them stays
/// still.
///
/// When this wrapper OWNS the tap ([onTap] set), it can fire a [haptic] on tap
/// — none by default: a press is not feedback of its own (docs/motion §9.5).
/// Pass e.g. [HapticKind.selection] for a chip, or fire the intent haptic
/// (`Haptics.commit()`, `Haptics.cartAdd()`) in [onTap]; never both. The
/// passive (no-onTap) path fires nothing, since the inner widget owns the
/// gesture — wire haptics in that inner handler.
///
/// [onPressChanged] hears the press go down and up — for a surface that
/// answers with a part of itself instead of dipping whole (the Mine header:
/// its avatar and name dip, the backdrop holds; pass [pressedScale] 1).
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = AppMotion.pressedScale,
    this.behavior = HitTestBehavior.opaque,
    this.enabled = true,
    this.haptic,
    this.onPressChanged,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final HitTestBehavior behavior;
  final bool enabled;

  /// Haptic fired on a tap THIS widget owns (null = none).
  final HapticKind? haptic;

  /// The finger went down on this press (true) or let go / left (false).
  final ValueChanged<bool>? onPressChanged;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  /// Which press owns each finger on screen: the first one to hear its
  /// pointer-down (the deepest — pointer events travel from the innermost
  /// hit outwards) claims it, and the presses around it stay still.
  static final Map<int, _PressScaleState> _owners = <int, _PressScaleState>{};

  bool _down = false;

  /// The finger this press owns, while it is down.
  int? _pointer;

  /// Where the passive press started: a finger that travels past the touch
  /// slop is scrolling, not pressing, so the press lets go.
  Offset? _downAt;

  bool get _passive => widget.onTap == null && widget.onLongPress == null;

  void _set(bool v) {
    if (!widget.enabled) return;
    if (v && _pointer == null) return;
    if (_down == v) return;
    setState(() => _down = v);
    widget.onPressChanged?.call(v);
  }

  void _pointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    final owner = _owners[event.pointer];
    if (owner != null && owner != this && owner.mounted) return;
    _owners[event.pointer] = this;
    _pointer = event.pointer;
    _downAt = event.position;
    if (_passive) _set(true);
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!_passive || event.pointer != _pointer) return;
    final start = _downAt;
    if (start != null && (event.position - start).distance > kTouchSlop) {
      _downAt = null;
      _set(false);
    }
  }

  void _pointerEnd(PointerEvent event) {
    if (_owners[event.pointer] == this) _owners.remove(event.pointer);
    if (event.pointer != _pointer) return;
    if (_passive) _set(false);
    _pointer = null;
  }

  void _handleTap() {
    if (widget.haptic != null) Haptics.fire(widget.haptic!);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _owners.removeWhere((_, owner) => owner == this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = (_down && !MotionGuard.reduced(context))
        ? widget.pressedScale
        : 1.0;
    final animated = AnimatedScale(
      scale: scale,
      // Press in quickly, let go a touch slower.
      duration: MotionGuard.duration(
        context,
        _down ? AppMotion.microPop : AppMotion.fast,
      ),
      curve: AppMotion.signature,
      child: widget.child,
    );

    // When this wrapper owns the tap, a GestureDetector handles it. When it
    // only decorates a child that owns its own gesture (an InkWell), the
    // passive Listener below drives the dip, so it never competes in the
    // gesture arena and steals the child's tap.
    final Widget body = _passive
        ? animated
        : GestureDetector(
            behavior: widget.behavior,
            onTap: widget.enabled && widget.onTap != null ? _handleTap : null,
            onLongPress: widget.enabled ? widget.onLongPress : null,
            // A disabled press stays out of the gesture arena, so a wrapper
            // (a BlockedTapShake) can still take the tap.
            onTapDown: widget.enabled ? (_) => _set(true) : null,
            onTapUp: widget.enabled ? (_) => _set(false) : null,
            onTapCancel: widget.enabled ? () => _set(false) : null,
            child: animated,
          );
    return Listener(
      onPointerDown: _pointerDown,
      onPointerMove: _pointerMove,
      onPointerUp: _pointerEnd,
      onPointerCancel: _pointerEnd,
      child: body,
    );
  }
}
