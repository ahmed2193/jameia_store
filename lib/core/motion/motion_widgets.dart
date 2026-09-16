/// **core/motion/motion_widgets.dart** — the reusable motion PRIMITIVES every
/// feature composes from. Each wrapper reads its timing/curve from [AppMotion]
/// and routes through [MotionGuard], so the OS "remove animations" flag degrades
/// the whole app to instant in one place. Feature code should reach for these
/// instead of hand-rolling `AnimatedSwitcher` / `AnimationController`.
///
/// Mirrors KeeTa's recurring interaction grammar: value flips (price / cart
/// total / free-ship threshold), tap press-scale, grow-from-zero pops (badges /
/// chips / check marks) and staggered list entrances.
library;

import 'package:flutter/material.dart';

import 'haptics.dart';
import 'motion.dart';

/// Value-swap FLIP — KeeTa's vertical price/total flip family
/// (`checkout_goods_price_flip`, `freeshipping_anim`, ~280ms). Swap the [child]
/// whenever [flipKey] changes; the outgoing value slides/fades out while the
/// incoming one settles in, sharing one [AppMotion.flip] token. Reduced-motion →
/// instant cut (duration collapses to zero via [MotionGuard]).
class FlipValue extends StatelessWidget {
  const FlipValue({
    super.key,
    required this.flipKey,
    required this.child,
    this.axis = Axis.vertical,
    this.alignment = AlignmentDirectional.centerStart,
  });

  /// Identity of the current value — when it changes, the flip plays.
  final Object flipKey;
  final Widget child;
  final Axis axis;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionGuard.duration(context, AppMotion.flip),
      switchInCurve: MotionGuard.curve(context, AppMotion.signature),
      switchOutCurve: MotionGuard.curve(context, AppMotion.exit),
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final begin = axis == Axis.vertical
            ? const Offset(0, 0.6)
            : const Offset(0.6, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<Object>(flipKey), child: child),
    );
  }
}

/// Tap-down PRESS-SCALE — the subtle "press" feel KeeTa gives every CTA / card /
/// chip: shrink to [pressedScale] on touch-down, settle back on release, over
/// [AppMotion.fast] with the signature ease-out. Wrap a tappable; supply [onTap]
/// here (the wrapper handles the gesture) OR leave [onTap] null to animate a
/// child that owns its own gesture. Reduced-motion → no scale.
///
/// When this wrapper OWNS the tap ([onTap] set), it also fires a [haptic] on tap
/// ([HapticKind.tap] by default — pass `null` to silence, or e.g.
/// [HapticKind.selection] for chips). The passive (no-onTap) path fires nothing,
/// since the inner widget owns the gesture — wire haptics in that inner handler.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.behavior = HitTestBehavior.opaque,
    this.enabled = true,
    this.haptic = HapticKind.tap,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final HitTestBehavior behavior;
  final bool enabled;

  /// Haptic fired on a tap THIS widget owns (null = none).
  final HapticKind? haptic;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled) return;
    if (_down != v) setState(() => _down = v);
  }

  void _handleTap() {
    if (widget.haptic != null) Haptics.fire(widget.haptic!);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scale = (_down && !MotionGuard.reduced(context))
        ? widget.pressedScale
        : 1.0;
    final animated = AnimatedScale(
      scale: scale,
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      child: widget.child,
    );

    // When this wrapper owns the tap, use a GestureDetector. When it's purely
    // decorating a child that owns its own gesture (e.g. an InkWell with ripple),
    // use a passive Listener so we never compete in the gesture arena and steal
    // the child's tap.
    if (widget.onTap == null && widget.onLongPress == null) {
      return Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: animated,
      );
    }
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.enabled && widget.onTap != null ? _handleTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: animated,
    );
  }
}

/// Grow-from-zero POP with overshoot — KeeTa's `scale_in` (0→1, 250ms) used by
/// badges, chips, check marks and the cart-count badge. Re-pops whenever
/// [popKey] changes (e.g. cart quantity ticks up). Reduced-motion → pinned at
/// the rest scale (no movement). Use [PopScale.onMount] for a one-shot entrance.
class PopScale extends StatefulWidget {
  const PopScale({
    super.key,
    required this.popKey,
    required this.child,
    this.duration,
    this.curve,
  });

  /// One-shot entrance pop on first build (no re-pop).
  const PopScale.onMount({
    super.key,
    required this.child,
    this.duration,
    this.curve,
  }) : popKey = const Object();

  final Object popKey;
  final Widget child;
  final Duration? duration;
  final Curve? curve;

  @override
  State<PopScale> createState() => _PopScaleState();
}

class _PopScaleState extends State<PopScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppMotion.medium,
    value: 1,
  );
  bool _firstPop = false;

  /// Pop the controller — but under reduced motion pin it to the rest scale so
  /// NO controller runs (the OS "remove animations" flag must leave the widget
  /// fully inert, not just visually static).
  void _play() {
    if (MotionGuard.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_firstPop) {
      _firstPop = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant PopScale old) {
    super.didUpdateWidget(old);
    if (old.popKey != widget.popKey) _play();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    return ScaleTransition(
      scale:
          Tween<double>(
            begin: AppMotion.popScaleBegin,
            end: AppMotion.popScaleEnd,
          ).animate(
            CurvedAnimation(
              parent: _c,
              curve: widget.curve ?? AppMotion.emphasized,
            ),
          ),
      child: widget.child,
    );
  }
}

/// Staggered list/grid ENTRANCE — each item fades + slides up by a small
/// [beginOffset], delayed by `index * stagger` so a freshly built feed/grid
/// cascades in (KeeTa home-feed / coupon-list / search-result reveal). Plays
/// once per element (guarded). Index delay is clamped by [maxIndex] so long
/// lists aren't held back. Reduced-motion → render immediately, no delay.
///
/// Default 30ms step is grounded: KeeTa's `home_page_main` staggered dropdown
/// reveal uses per-item delays of 0/30/60ms (docs/keeta_motion_reference.md §2).
class StaggerEntrance extends StatefulWidget {
  const StaggerEntrance({
    super.key,
    required this.index,
    required this.child,
    this.stagger = const Duration(milliseconds: 30),
    this.beginOffset = const Offset(0, 0.08),
    this.maxIndex = 10,
  });

  final int index;
  final Widget child;
  final Duration stagger;
  final Offset beginOffset;
  final int maxIndex;

  @override
  State<StaggerEntrance> createState() => _StaggerEntranceState();
}

class _StaggerEntranceState extends State<StaggerEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return;
    _played = true;
    if (MotionGuard.reduced(context)) {
      _c.value = 1;
      return;
    }
    final steps = widget.index.clamp(0, widget.maxIndex);
    Future<void>.delayed(widget.stagger * steps, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.signature);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
