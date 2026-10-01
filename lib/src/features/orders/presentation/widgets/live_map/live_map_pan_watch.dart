import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Tells [onPanned] once when a finger drags the map (pan, pinch): the
/// customer took the camera, so the map stops following the rider. A tap
/// is not a drag. It only listens — the map still gets every touch.
class LiveMapPanWatch extends StatefulWidget {
  const LiveMapPanWatch({
    super.key,
    required this.onPanned,
    required this.child,
  });

  final VoidCallback onPanned;
  final Widget child;

  @override
  State<LiveMapPanWatch> createState() => _LiveMapPanWatchState();
}

class _LiveMapPanWatchState extends State<LiveMapPanWatch> {
  final Map<int, Offset> _downAt = <int, Offset>{};
  bool _told = false;

  void _down(PointerDownEvent event) {
    if (_downAt.isEmpty) _told = false;
    _downAt[event.pointer] = event.position;
  }

  void _move(PointerMoveEvent event) {
    final start = _downAt[event.pointer];
    if (_told || start == null) return;
    if ((event.position - start).distance < kTouchSlop) return;
    _told = true;
    widget.onPanned();
  }

  void _up(PointerEvent event) => _downAt.remove(event.pointer);

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: _up,
    child: widget.child,
  );
}
