import 'package:flutter/foundation.dart';

import 'shell_tabs.dart';

/// `extra` for [Routes.login]: whether sign-in opened because the session
/// expired ([sessionExpired]; a bare `true` extra — what the app root sends
/// on expiry — still means that), and the way back once the customer is in,
/// or leaves as a guest from a sign-in that is the whole stack: the shell on
/// [returnTab], with the page that asked for the sign-in ([returnTo], opened
/// again with [returnExtra]) on top of it. `SignInFlow` builds and follows it.
@immutable
class LoginArgs {
  const LoginArgs({
    this.sessionExpired = false,
    this.returnTo,
    this.returnExtra,
    this.returnTab = ShellTab.home,
  });

  /// Reads a login route's `extra`: these args, `true` (expired), or nothing.
  factory LoginArgs.from(Object? extra) => switch (extra) {
    final LoginArgs args => args,
    true => const LoginArgs(sessionExpired: true),
    _ => const LoginArgs(),
  };

  final bool sessionExpired;

  /// The location the customer returns to, opened on top of the main shell
  /// (so "back" from it lands on [returnTab]); `null` = the shell alone.
  final String? returnTo;

  /// The `extra` [returnTo] was opened with (an order, an order id …).
  final Object? returnExtra;

  /// The shell tab under [returnTo], or on screen when there is none.
  final ShellTab returnTab;
}
