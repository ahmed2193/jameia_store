import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/route_args/login_args.dart';
import '../../config/routes/route_args/shell_arrival.dart';
import '../../config/routes/route_args/shell_tabs.dart';
import '../../config/routes/routes.dart';

/// Sign-in ends where it began. A screen that needs the customer signed in
/// [open]s it, and it remembers the way back; the sign-in pages [leave] by
/// that way — once the customer is in, or as a guest from a sign-in that is
/// the whole stack.
abstract final class SignInFlow {
  /// The paths that build the main shell.
  static const Set<String> _shellPaths = {Routes.shell, Routes.home};

  /// From a screen that asks the customer to sign in (its signed-out state,
  /// a 401 over the data on it): sign-in with `go`, so once the customer is
  /// in the stack is built again and every page cubit starts for the new
  /// session. The way back is the page on top — its location and `extra`
  /// (the router's own: a sheet over the page is not a route) — or, in the
  /// main shell, [tab].
  static void open(BuildContext context, {ShellTab tab = ShellTab.home}) {
    final here = GoRouter.of(context).state;
    final inShell = _shellPaths.contains(here.uri.path);
    context.go(
      Routes.login,
      extra: inShell
          ? LoginArgs(returnTab: tab)
          : LoginArgs(returnTo: here.uri.toString(), returnExtra: here.extra),
    );
  }

  /// Out of sign-in by the way [args] names: the shell on its tab (with
  /// `go`, so the stack is the shell alone), then — a frame later, once it
  /// is — the page that asked for the sign-in on top of it, so "back" from
  /// that page lands on the tab.
  static void leave(BuildContext context, LoginArgs args) {
    final router = GoRouter.of(context);
    router.go(Routes.shell, extra: ShellArrival(tab: args.returnTab));
    final location = args.returnTo;
    if (location == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.push<void>(location, extra: args.returnExtra);
    });
  }
}
