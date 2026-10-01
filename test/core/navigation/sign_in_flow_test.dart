import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/route_args/login_args.dart';
import 'package:hero_mart/src/config/routes/route_args/shell_arrival.dart';
import 'package:hero_mart/src/config/routes/route_args/shell_tabs.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/navigation/sign_in_flow.dart';

/// A page with one button that runs [onTap] with the page's own context.
class _Page extends StatelessWidget {
  const _Page(this.label, this.onTap);

  final String label;
  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(onPressed: () => onTap(context), child: Text(label)),
    ),
  );
}

void _openFromCartTab(BuildContext context) =>
    SignInFlow.open(context, tab: ShellTab.cart);

void main() {
  const pagePath = '/page';
  Object? loginExtra;

  Future<GoRouter> pumpRouter(WidgetTester tester, String location) async {
    loginExtra = null;
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: Routes.shell,
          builder: (_, _) => const _Page('shell', _openFromCartTab),
        ),
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const _Page('home', _openFromCartTab),
        ),
        GoRoute(
          path: pagePath,
          builder: (_, state) => _Page('page ${state.extra}', _openFromCartTab),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, state) {
            loginExtra = state.extra;
            final args = LoginArgs.from(state.extra);
            return _Page('login', (context) => SignInFlow.leave(context, args));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a pushed page: sign-in comes back to it, with its extra, '
      'over the shell', (tester) async {
    final router = await pumpRouter(tester, Routes.shell);
    router.push<void>('$pagePath?from=offer', extra: 'order-7');
    await tester.pumpAndSettle();

    await tester.tap(find.text('page order-7'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.login);
    expect(router.canPop(), isFalse, reason: 'sign-in is opened with go');
    final args = loginExtra! as LoginArgs;
    expect(args.returnTo, '$pagePath?from=offer');
    expect(args.returnExtra, 'order-7');
    expect(args.returnTab, ShellTab.home);

    await tester.tap(find.text('login'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '$pagePath?from=offer');
    expect(router.state.extra, 'order-7');
    expect(find.text('page order-7'), findsOneWidget);

    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.shell);
    expect((router.state.extra! as ShellArrival).tab, ShellTab.home);
  });

  testWidgets('in the shell: sign-in comes back to the tab it was opened '
      'from, with nothing on top', (tester) async {
    final router = await pumpRouter(tester, Routes.shell);

    await tester.tap(find.text('shell'));
    await tester.pumpAndSettle();
    final args = loginExtra! as LoginArgs;
    expect(args.returnTo, isNull);
    expect(args.returnExtra, isNull);
    expect(args.returnTab, ShellTab.cart);

    await tester.tap(find.text('login'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.shell);
    expect((router.state.extra! as ShellArrival).tab, ShellTab.cart);
    expect(router.canPop(), isFalse);
  });

  testWidgets('/home is the shell too', (tester) async {
    await pumpRouter(tester, Routes.home);

    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    final args = loginExtra! as LoginArgs;
    expect(args.returnTo, isNull);
    expect(args.returnTab, ShellTab.cart);
  });

  testWidgets('an expired session (a bare true extra) leaves for Home', (
    tester,
  ) async {
    final router = await pumpRouter(tester, Routes.shell);
    router.go(Routes.login, extra: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('login'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.shell);
    expect((router.state.extra! as ShellArrival).tab, ShellTab.home);
  });
}
