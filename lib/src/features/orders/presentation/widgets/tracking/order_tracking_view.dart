import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/navigation/navigation.dart';
import '../../cubit/order_tracking_cubit.dart';
import 'tracking_scaffold.dart';

/// Owns the visibility of the tracking page: it subscribes to the router's
/// [routeObserver] (covered by another page) and to the app lifecycle
/// (backgrounded), and tells the cubit when to poll.
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
  Widget build(BuildContext context) => const TrackingScaffold();
}
