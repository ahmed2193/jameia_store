import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/haptics.dart';
import '../../../../core/widgets/connectivity_scope.dart';
import '../cubit/connectivity_banner_mode.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';
import 'connectivity_banner_frame.dart';

/// The one host of the global connection banner, placed in
/// `MaterialApp.router(builder:)` so it sits above every route, sheet and
/// dialog. It:
///
///   * pauses the reachability monitor while the app is in the background
///     and resumes it (with a check) on return — zero probes in background;
///   * fills [ConnectivityScope] for everything below it;
///   * keeps the banner off the splash ([isOnSplash], re-read on every
///     [routeChanges] notification);
///   * turns a scope nudge into one shake of the banner + a light haptic;
///   * hands the cubit's live checks to the scope (a submit's
///     [ConnectivityCubit.confirmOnline], a failed load's
///     [ConnectivityCubit.recheckForRetry]) — the policies are the cubit's.
///
/// [child] (the router's navigator) is passed through untouched: a status
/// change rebuilds the bar and the scope's dependents, never the routes.
class ConnectivityBannerHost extends StatefulWidget {
  const ConnectivityBannerHost({
    super.key,
    required this.routeChanges,
    required this.isOnSplash,
    required this.child,
  });

  /// Notifies on every navigation (the router's delegate).
  final Listenable routeChanges;

  /// Whether the current route is the splash.
  final bool Function() isOnSplash;
  final Widget child;

  @override
  State<ConnectivityBannerHost> createState() => _ConnectivityBannerHostState();
}

class _ConnectivityBannerHostState extends State<ConnectivityBannerHost> {
  late final AppLifecycleListener _lifecycle;
  final ValueNotifier<int> _nudges = ValueNotifier<int>(0);
  late bool _allowed = !widget.isOnSplash();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    widget.routeChanges.addListener(_onRoute);
  }

  @override
  void didUpdateWidget(ConnectivityBannerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeChanges == widget.routeChanges) return;
    oldWidget.routeChanges.removeListener(_onRoute);
    widget.routeChanges.addListener(_onRoute);
  }

  @override
  void dispose() {
    widget.routeChanges.removeListener(_onRoute);
    _lifecycle.dispose();
    _nudges.dispose();
    super.dispose();
  }

  void _onRoute() {
    final allowed = !widget.isOnSplash();
    if (allowed != _allowed) setState(() => _allowed = allowed);
  }

  void _onLifecycle(AppLifecycleState lifecycle) {
    final connectivity = context.read<ConnectivityCubit>();
    switch (lifecycle) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        connectivity.pause();
      case AppLifecycleState.resumed:
        connectivity.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _nudge() {
    if (!_allowed || !context.read<ConnectivityCubit>().state.isOffline) {
      return;
    }
    // An action that needs the internet: the one refusal buzz (§9.5).
    Haptics.refuse();
    _nudges.value++;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConnectivityCubit, ConnectivityState, (bool, int)>(
      selector: (state) => (state.isOffline, state.reconnectEpoch),
      builder: (context, scope) => ConnectivityScope(
        isOffline: scope.$1,
        reconnectEpoch: scope.$2,
        onNudge: _nudge,
        checkOnline: context.read<ConnectivityCubit>().confirmOnline,
        recheckForRetry: context.read<ConnectivityCubit>().recheckForRetry,
        child:
            BlocSelector<
              ConnectivityCubit,
              ConnectivityState,
              ConnectivityBannerMode
            >(
              selector: (state) => state.bannerMode,
              builder: (context, mode) => ConnectivityBannerFrame(
                mode: _allowed ? mode : ConnectivityBannerMode.hidden,
                nudges: _nudges,
                child: widget.child,
              ),
            ),
      ),
    );
  }
}
