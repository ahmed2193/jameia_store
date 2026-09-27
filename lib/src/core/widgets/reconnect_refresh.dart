import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import 'connectivity_scope.dart';

/// Calls [onReconnected] once each time the connection comes back (the
/// [ConnectivityScope] reconnect epoch moves) — after a random wait of up to
/// [AppConstants.reconnectJitter], so the screens that come back together do
/// not hit the backend in the same instant. The screen's cubit decides
/// whether anything needs a request (only stale or failed data does).
/// [child] is passed through: a reconnect never rebuilds it.
class ReconnectRefresh extends StatefulWidget {
  const ReconnectRefresh({
    super.key,
    required this.onReconnected,
    required this.child,
    this.random,
  });

  final VoidCallback onReconnected;
  final Widget child;

  /// The jitter's source (tests pin it).
  final Random? random;

  @override
  State<ReconnectRefresh> createState() => _ReconnectRefreshState();
}

class _ReconnectRefreshState extends State<ReconnectRefresh> {
  static final Random _shared = Random();

  int? _epoch;
  Timer? _pending;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final epoch = ConnectivityScope.reconnectEpochOf(context);
    final previous = _epoch;
    _epoch = epoch;
    if (previous == null || previous == epoch) return;
    _pending?.cancel();
    final jitter = (widget.random ?? _shared).nextInt(
      AppConstants.reconnectJitter.inMilliseconds + 1,
    );
    _pending = Timer(Duration(milliseconds: jitter), () {
      _pending = null;
      if (mounted) widget.onReconnected();
    });
  }

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
