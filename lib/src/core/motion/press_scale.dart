import 'package:flutter/material.dart';

import 'haptics.dart';
import 'motion.dart';

/// Tap-down PRESS-SCALE — the subtle "press" feel Jameia gives every CTA / card /
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
