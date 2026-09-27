import 'package:flutter/widgets.dart';

/// Builds with `settled: false` while the enclosing route is still arriving
/// and with `settled: true` once its entrance has completed, so an entrance
/// of its own (a rail reveal, a hint bubble) starts on a still page instead
/// of fighting the route transition.
///
/// With no route, or a route that has already arrived, `settled` turns true
/// right after the first frame. It never turns back to false. A pushed
/// route spends its first frame offstage for the hero measurement, where
/// its animation reads "complete"; that frame does not count. One status
/// listener is held on the route's animation until it completes or this
/// widget is disposed.
///
/// A route change (a sheet opening on top) rebuilds [builder]: hand it a
/// prebuilt child so only the wrapper it returns is rebuilt.
class OnRouteSettled extends StatefulWidget {
  const OnRouteSettled({super.key, required this.builder});

  final Widget Function(BuildContext context, bool settled) builder;

  @override
  State<OnRouteSettled> createState() => _OnRouteSettledState();
}

class _OnRouteSettledState extends State<OnRouteSettled> {
  ModalRoute<Object?>? _route;
  bool _checking = false;

  /// The route's entrance, while it still runs.
  Animation<double>? _entrance;
  bool _settled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settled) return;
    final route = ModalRoute.of(context);
    if (_checking && identical(route, _route)) return;
    _route = route;
    _checking = true;
    _release();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  /// Settles when the route is onstage with its entrance complete;
  /// otherwise waits on the entrance (and, while the route is still
  /// offstage, looks again after the next frame).
  void _check() {
    if (!mounted || _settled) return;
    final route = _route;
    final entrance = route?.animation;
    if (route == null || entrance == null) {
      _settle();
      return;
    }
    if (entrance.isCompleted && !route.offstage) {
      _settle();
      return;
    }
    _entrance ??= entrance..addStatusListener(_onEntrance);
    if (route.offstage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  void _onEntrance(AnimationStatus status) {
    if (status == AnimationStatus.completed) _check();
  }

  void _release() {
    _entrance?.removeStatusListener(_onEntrance);
    _entrance = null;
  }

  void _settle() {
    _release();
    if (!mounted || _settled) return;
    setState(() => _settled = true);
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _settled);
}
