import 'package:flutter/foundation.dart';

/// `extra` for [Routes.login] when the sign-in should lead somewhere: back to
/// the page that asked for it ([returnTo], e.g. the Pro page's "Sign in to
/// join"), or with the "session expired" notice ([sessionExpired]). A bare
/// `true` extra — what the app root sends on expiry — still means expired.
@immutable
class LoginArgs {
  const LoginArgs({this.sessionExpired = false, this.returnTo});

  /// Reads a login route's `extra`: these args, `true` (expired), or nothing.
  factory LoginArgs.from(Object? extra) => switch (extra) {
    final LoginArgs args => args,
    true => const LoginArgs(sessionExpired: true),
    _ => const LoginArgs(),
  };

  final bool sessionExpired;

  /// The location the customer returns to once signed in, opened on top of
  /// the main shell (so "back" from it lands home); `null` = the shell.
  final String? returnTo;
}
