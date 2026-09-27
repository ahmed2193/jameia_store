import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../error/failures.dart';
import '../utils/failure_message.dart';
import '../widgets/connectivity_scope.dart';

/// The one way to show a transient message: replaces any snack bar still on
/// screen so rapid taps never queue a backlog.
void showJameiaSnackBar(
  BuildContext context,
  String message, {
  SnackBarBehavior? behavior,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(behavior: behavior, content: Text(message)));
}

/// The one way to tell the customer a request failed.
///
/// A READ that failed in transport (no connection, timeout) shows nothing of
/// its own: the failure already asked for a connection check, and the
/// banner — once that check confirms it — and the screen's stale note speak.
/// Never a "No internet" toast before the app knows (while offline the
/// banner is nudged). A failed [action] (a submit, a save, a toggle: the
/// customer's input is kept) says "you're offline, your changes are kept"
/// once for a lost connection (and nudges the banner), its own message
/// otherwise. Anything else shows [FailureMessage.localizedMessage].
void showFailureSnackBar(
  BuildContext context,
  Failure failure, {
  bool action = false,
}) {
  final offline = ConnectivityScope.readIsOffline(context);
  if (offline && failure.isTransport) ConnectivityScope.nudge(context);
  if (action) {
    showJameiaSnackBar(
      context,
      failure.isConnectionLoss(offline: offline)
          ? 'connectivity.action_needs_internet'.tr()
          : failure.localizedMessage,
    );
    return;
  }
  if (failure.isTransport) return;
  showJameiaSnackBar(context, failure.localizedMessage);
}
