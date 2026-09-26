import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';

/// A light press for a card that owns its own tap (a product card, a recipe
/// card, the search pill): it sinks a touch under the finger and comes back
/// up on release — or as soon as the finger starts to drag, so a card never
/// rides a scrolling rail pressed in. It only listens: the card's own tap,
/// ripple and buttons work as before.
class HomePressable extends StatefulWidget {
  const HomePressable({super.key, required this.child});

  final Widget child;

  @override
  State<HomePressable> createState() => _HomePressableState();
}

class _HomePressableState extends State<HomePressable> {
  static const double _pressedScale = 0.97;

  Offset? _downAt;
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  void _down(PointerDownEvent event) {
    _downAt = event.position;
    _set(true);
  }

  void _move(PointerMoveEvent event) {
    final downAt = _downAt;
    if (downAt != null && (event.position - downAt).distance > kTouchSlop) {
      _up(event);
    }
  }

  void _up(PointerEvent event) {
    _downAt = null;
    _set(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedScale(
        scale: _pressed && !MotionGuard.reduced(context) ? _pressedScale : 1,
        duration: MotionGuard.duration(context, AppMotion.fast),
        curve: AppMotion.signature,
        child: widget.child,
      ),
    );
  }
}
