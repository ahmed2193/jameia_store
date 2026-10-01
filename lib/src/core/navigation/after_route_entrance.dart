import 'package:flutter/widgets.dart';

/// Builds [child] once the route it sits in has finished coming in, and
/// [placeholder] until then — for a heavy view (a native map, a camera
/// preview) whose creation would drop frames of the page transition. A
/// route that is already in, or no route, builds [child] at once. Rebuilds
/// once, on the landing, never per frame.
class AfterRouteEntrance extends StatefulWidget {
  const AfterRouteEntrance({
    super.key,
    required this.child,
    this.placeholder = const SizedBox.expand(),
  });

  final Widget child;
  final Widget placeholder;

  @override
  State<AfterRouteEntrance> createState() => _AfterRouteEntranceState();
}

class _AfterRouteEntranceState extends State<AfterRouteEntrance> {
  ModalRoute<Object?>? _route;
  Animation<double>? _entrance;
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entered) return;
    _route = ModalRoute.of(context);
    _listenTo(_route?.animation);
    if (_isIn) _enter();
  }

  @override
  void dispose() {
    _listenTo(null);
    super.dispose();
  }

  /// In once the entrance is complete — but not while the route is measured
  /// offstage (the frame before a hero flight), when it reads complete.
  bool get _isIn {
    final route = _route;
    final entrance = _entrance;
    if (route == null || entrance == null) return true;
    return entrance.isCompleted && !route.offstage;
  }

  void _listenTo(Animation<double>? entrance) {
    if (entrance == _entrance) return;
    _entrance?.removeStatusListener(_statusChanged);
    _entrance = entrance;
    entrance?.addStatusListener(_statusChanged);
  }

  void _statusChanged(AnimationStatus _) {
    if (_entered || !mounted || !_isIn) return;
    setState(_enter);
  }

  void _enter() {
    _entered = true;
    _listenTo(null);
  }

  @override
  Widget build(BuildContext context) =>
      _entered ? widget.child : widget.placeholder;
}
