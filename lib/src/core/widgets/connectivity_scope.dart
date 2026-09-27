import 'package:flutter/widgets.dart';

import '../domain/entities/connection_recheck.dart';

/// The part of [ConnectivityScope] a widget depends on.
enum ConnectivityAspect { offline, reconnect }

/// Connection awareness for core widgets and pages without importing the
/// connectivity feature. The global banner host fills it from the app-global
/// `ConnectivityCubit`; outside a scope (a test that does not pump one)
/// everything reads as online.
///
/// Dependents name their aspect, so a widget that only cares about "offline"
/// is not rebuilt by a reconnect, and nobody is rebuilt when a callback
/// changes identity. The policies behind [checkOnline] and [recheckForRetry]
/// live in the `ConnectivityCubit`; the scope only carries them.
class ConnectivityScope extends InheritedModel<ConnectivityAspect> {
  const ConnectivityScope({
    super.key,
    required this.isOffline,
    required this.reconnectEpoch,
    required this.onNudge,
    this.checkOnline,
    this.recheckForRetry,
    required super.child,
  });

  final bool isOffline;

  /// Bumped once per offline → online recovery.
  final int reconnectEpoch;

  /// Shakes the banner once (with a light haptic).
  final VoidCallback onNudge;

  /// A live check before a submit: `true` unless it found no connection.
  /// `null` outside the app's banner host.
  final Future<bool> Function()? checkOnline;

  /// A load failed in transport while the app did not read as offline: a
  /// live check, answering whether the load goes again now. `null` outside
  /// the app's banner host.
  final Future<ConnectionRecheck> Function()? recheckForRetry;

  /// Offline now; rebuilds the caller when that changes.
  static bool isOfflineOf(BuildContext context) =>
      InheritedModel.inheritFrom<ConnectivityScope>(
        context,
        aspect: ConnectivityAspect.offline,
      )?.isOffline ??
      false;

  /// The recovery count; rebuilds the caller when the connection comes back.
  static int reconnectEpochOf(BuildContext context) =>
      InheritedModel.inheritFrom<ConnectivityScope>(
        context,
        aspect: ConnectivityAspect.reconnect,
      )?.reconnectEpoch ??
      0;

  /// Offline now, read WITHOUT depending on it — for listeners and taps.
  static bool readIsOffline(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ConnectivityScope>()?.isOffline ??
      false;

  /// A network action was tried while offline: point at the banner instead of
  /// showing a message of its own. No-op outside a scope.
  static void nudge(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ConnectivityScope>()?.onNudge();

  /// Before a submit that is never queued (placing an order, cancelling
  /// one): while the app reads as offline, a live check first. `true` when
  /// the submit may go — online, or outside a scope; offline with no checker
  /// it answers what the scope knows.
  static Future<bool> confirmOnline(BuildContext context) async {
    final scope = context.getInheritedWidgetOfExactType<ConnectivityScope>();
    if (scope == null || !scope.isOffline) return true;
    final check = scope.checkOnline;
    return check != null && await check();
  }

  /// For a screen whose first load failed for want of a connection while the
  /// app did not read as offline — maybe one slow request, maybe the
  /// connection is gone: the live check to run before the screen says
  /// anything ([ConnectionRecheck]). `null` outside the app's banner host:
  /// nothing can check.
  static Future<ConnectionRecheck> Function()? recheckerOf(
    BuildContext context,
  ) => context
      .getInheritedWidgetOfExactType<ConnectivityScope>()
      ?.recheckForRetry;

  @override
  bool updateShouldNotify(ConnectivityScope oldWidget) =>
      isOffline != oldWidget.isOffline ||
      reconnectEpoch != oldWidget.reconnectEpoch;

  @override
  bool updateShouldNotifyDependent(
    ConnectivityScope oldWidget,
    Set<ConnectivityAspect> dependencies,
  ) =>
      (dependencies.contains(ConnectivityAspect.offline) &&
          isOffline != oldWidget.isOffline) ||
      (dependencies.contains(ConnectivityAspect.reconnect) &&
          reconnectEpoch != oldWidget.reconnectEpoch);
}
