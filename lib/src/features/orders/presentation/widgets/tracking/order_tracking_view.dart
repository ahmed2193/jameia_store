import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../cubit/order_tracking_cubit.dart';
import 'tracking_scaffold.dart';

/// Owns when the tracking page polls: it subscribes to the router's
/// [routeObserver] (covered by another page), to the app lifecycle
/// (backgrounded) and to the connection (offline), and tells the cubit. The
/// connection coming back polls once right away.
class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView>
    with RouteAware, WidgetsBindingObserver {
  bool _onTop = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) routeObserver.subscribe(this, route);
    context.read<OrderTrackingCubit>().setOffline(
      ConnectivityScope.isOfflineOf(context),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPushNext() => _setVisible(onTop: false);

  @override
  void didPopNext() => _setVisible(onTop: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _setVisible(foreground: state == AppLifecycleState.resumed);

  void _setVisible({bool? onTop, bool? foreground}) {
    _onTop = onTop ?? _onTop;
    _foreground = foreground ?? _foreground;
    if (!mounted) return;
    context.read<OrderTrackingCubit>().setVisible(_onTop && _foreground);
  }

  // `ModalRoute.of` above rebuilds this State on every push / pop over the
  // page; the const frame is skipped, so nothing below it rebuilds.
  @override
  Widget build(BuildContext context) => ReconnectRefresh(
    onReconnected: () => context.read<OrderTrackingCubit>().onReconnected(),
    child: const TrackingScaffold(),
  );
}
