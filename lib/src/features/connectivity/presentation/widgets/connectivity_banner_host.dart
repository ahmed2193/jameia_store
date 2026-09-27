import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/widgets/connectivity_scope.dart';
import '../../domain/entities/connectivity_status.dart';
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
///   * answers a screen whose load failed in transport while the app did
///     not read as offline ([ConnectivityScope.recheckerOf]): a live check, and
///     at most one automatic retry per [AppConstants.readRetryGap].
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
  DateTime? _lastAutoRetry;

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

  /// A submit that needs the network asks for a live check; anything but a
  /// confirmed "offline" lets it try (the probe can be wrong).
  Future<bool> _checkNow() async =>
      await context.read<ConnectivityCubit>().checkNow() !=
      ConnectivityStatus.offline;

  Future<bool> _recheck() async {
    final found = await context.read<ConnectivityCubit>().checkNow();
    if (found == ConnectivityStatus.offline) return false;
    final now = DateTime.now();
    final last = _lastAutoRetry;
    if (last != null && now.difference(last) < AppConstants.readRetryGap) {
      return false;
    }
    _lastAutoRetry = now;
    return true;
  }

  void _nudge() {
    if (!_allowed || !context.read<ConnectivityCubit>().state.isOffline) {
      return;
    }
    Haptics.tap();
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
        onCheckNow: _checkNow,
        onRecheck: _recheck,
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
