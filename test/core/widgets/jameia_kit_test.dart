// The Jameia* kit the search and cart / checkout / orders screens are built
// from: money reads left-to-right with the localized label, links announce
// themselves, the signed-out state signs in with `go`, choice rows are
// checkable, list cards put hairlines only between rows and the title bar
// never offers a back button on a root route.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/core/utils/formatters.dart';
import 'package:jameia_mart/src/core/widgets/app_button.dart';
import 'package:jameia_mart/src/core/widgets/jameia_list_card.dart';
import 'package:jameia_mart/src/core/widgets/jameia_money_text.dart';
import 'package:jameia_mart/src/core/widgets/jameia_state_view.dart';
import 'package:jameia_mart/src/core/widgets/jameia_text_link.dart';
import 'package:jameia_mart/src/core/widgets/jameia_title_bar.dart';
import 'package:jameia_mart/src/core/widgets/option_row.dart';
import 'package:jameia_mart/src/core/widgets/round_back_button.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  tearDown(() => Intl.defaultLocale = null);

  group('money', () {
    test('priceLtr leads with the label in both languages', () {
      Intl.defaultLocale = 'en';
      expect(Formatters.priceLtr(1.25), 'KD 1.250');
      Intl.defaultLocale = 'ar';
      expect(Formatters.priceLtr(1.25), 'د.ك 1.250');
      expect(Formatters.price(1.25), '1.250 د.ك');
    });

    testWidgets('JameiaMoneyText is one LTR run read as the price', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      Intl.defaultLocale = 'ar';
      await tester.pumpWidget(
        _host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: JameiaMoneyText(kd: 0.5, negative: true),
          ),
        ),
      );

      final text = find.text('- د.ك 0.500');
      expect(text, findsOneWidget);
      final direction = tester.widget<Directionality>(
        find.ancestor(of: text, matching: find.byType(Directionality)).first,
      );
      expect(direction.textDirection, TextDirection.ltr);
      expect(find.bySemanticsLabel('- 0.500 د.ك'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('JameiaTextLink', () {
    testWidgets('announces a link, or a button for an in-page action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              JameiaTextLink(label: 'View all', onTap: () {}),
              JameiaTextLink(label: 'Clear', navigates: false, onTap: () {}),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(JameiaTextLink).first),
        isSemantics(label: 'View all', isLink: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.byType(JameiaTextLink).last),
        isSemantics(label: 'Clear', isButton: true, isLink: false),
      );
      semantics.dispose();
    });

    testWidgets('without onTap it is disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const JameiaTextLink(label: 'Clear cart', onTap: null)),
      );
      expect(
        tester.getSemantics(find.byType(JameiaTextLink)),
        isSemantics(label: 'Clear cart', isEnabled: false),
      );
      semantics.dispose();
    });
  });

  testWidgets('signed-out state goes to sign-in', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: JameiaStateView.signedOut(message: 'Sign in to see orders'),
          ),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Sign in to see orders'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.text('login page'), findsOneWidget);
  });

  group('OptionRow', () {
    testWidgets('is a checkable member of its group', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(OptionRow(title: 'Cash', selected: true, onTap: () {})),
      );
      expect(
        tester.getSemantics(find.byType(OptionRow)),
        isSemantics(
          label: 'Cash',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('a disabled row ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          OptionRow(
            title: 'Wallet',
            selected: false,
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Wallet'));
      expect(taps, 0);
    });
  });

  testWidgets('JameiaListCard puts a hairline between rows only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const JameiaListCard(
          children: [Text('one'), Text('two'), Text('three')],
        ),
      ),
    );
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('title bar offers back only when there is somewhere to go', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(appBar: JameiaTitleBar(title: 'Root')),
        ),
        GoRoute(
          path: '/next',
          builder: (_, _) =>
              const Scaffold(appBar: JameiaTitleBar(title: 'Next')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(RoundBackButton), findsNothing);

    router.push('/next');
    await tester.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
    expect(find.byType(RoundBackButton), findsOneWidget);
  });
}
