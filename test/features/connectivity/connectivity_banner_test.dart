// The global connection banner over a MaterialApp, driven by a real
// ConnectivityCubit on scripted reports: offline → reconnecting → back online
// → gone; it pushes the app down (the page loses its top inset while the bar
// covers the status bar, and gets it back after); never over the splash;
// a nudge shakes it; the routes below are never rebuilt by a status change;
// Arabic + RTL, 1.3× text, reduced motion (no running ticker) and the live
// region semantics.

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/constants/app_constants.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/domain/entities/connection_recheck.dart';
import 'package:hero_mart/src/core/motion/shake_x.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/features/connectivity/domain/entities/connectivity_status.dart';
import 'package:hero_mart/src/features/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'package:hero_mart/src/features/connectivity/presentation/widgets/connectivity_bar_content.dart';
import 'package:hero_mart/src/features/connectivity/presentation/widgets/connectivity_banner_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_test_fakes.dart';

/// Counts its builds and records the top inset it was laid out with.
class _Page extends StatelessWidget {
  const _Page(this.builds);

  final List<int> builds;

  @override
  Widget build(BuildContext context) {
    builds.add(builds.length);
    return const Scaffold(body: Center(child: Text('page body')));
  }
}

late Map<String, dynamic> _en;
late Map<String, dynamic> _ar;

void _useLanguage(String code) => Localization.load(
  Locale(code),
  translations: Translations(code == 'ar' ? _ar : _en),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    _en = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    _ar = json.decode(
      await rootBundle.loadString('assets/i18n/ar.json'),
    ) as Map<String, dynamic>;
  });

  late FakeConnectivityRepository repository;
  late ConnectivityCubit cubit;
  late List<int> pageBuilds;
  late ValueNotifier<int> routes;
  late bool onSplash;

  setUp(() {
    _useLanguage('en');
    repository = FakeConnectivityRepository();
    pageBuilds = [];
    routes = ValueNotifier<int>(0);
    onSplash = false;
  });

  tearDown(() => routes.dispose());

  Future<void> pumpHost(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    bool reducedMotion = false,
    DateTime Function()? now,
  }) async {
    tester.view.padding = const FakeViewPadding(top: 72); // 24 dp status bar
    addTearDown(tester.view.reset);
    // Built inside the test body: its timers must run on the fake clock.
    cubit = buildConnectivityCubit(repository, now: now)..start();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: Directionality(
            textDirection: direction,
            child: BlocProvider<ConnectivityCubit>.value(
              value: cubit,
              child: ConnectivityBannerHost(
                routeChanges: routes,
                isOnSplash: () => onSplash,
                child: child!,
              ),
            ),
          ),
        ),
        home: _Page(pageBuilds),
      ),
    );
  }

  /// The monitor reports [status], and the check that confirms "offline"
  /// finds the same.
  Future<void> report(WidgetTester tester, ConnectivityStatus status) async {
    repository
      ..checkResult = status
      ..report(status);
    await tester.pump();
    await tester.pump(testOfflineAfter * 2);
    await tester.pumpAndSettle();
  }

  double pageInset(WidgetTester tester) =>
      MediaQuery.paddingOf(tester.element(find.text('page body'))).top;

  testWidgets('unknown and online show nothing', (tester) async {
    await pumpHost(tester);
    expect(find.text("You're offline"), findsNothing);
    await report(tester, ConnectivityStatus.online);
    expect(find.byType(ConnectivityBarContent), findsNothing);
    expect(pageInset(tester), 24);
  });

  testWidgets('offline pushes the app down and takes the status bar', (
    tester,
  ) async {
    await pumpHost(tester);
    final before = tester.getTopLeft(find.text('page body')).dy;
    await report(tester, ConnectivityStatus.offline);

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Showing what you last saw'), findsOneWidget);
    // The page no longer pads for the status bar: the bar covers it.
    expect(pageInset(tester), 0);
    expect(tester.getTopLeft(find.text('page body')).dy, greaterThan(before));
    expect(
      tester.getTopLeft(find.byType(ConnectivityBarContent)).dy,
      24,
      reason: 'the row sits right under the status bar strip',
    );
  });

  testWidgets("the bar's text sits on a Material: the app theme's style, "
      'never the fallback underline', (tester) async {
    await pumpHost(tester);
    await report(tester, ConnectivityStatus.offline);

    final texts = tester.widgetList<RichText>(
      find.descendant(
        of: find.byType(ConnectivityBarContent),
        matching: find.byType(RichText),
      ),
    );
    expect(texts, isNotEmpty);
    for (final text in texts) {
      expect(
        text.text.style?.decoration,
        anyOf(isNull, TextDecoration.none),
        reason: text.text.toPlainText(),
      );
    }
  });

  testWidgets('tap → Reconnecting…, still offline → back to offline', (
    tester,
  ) async {
    await pumpHost(tester);
    await report(tester, ConnectivityStatus.offline);
    repository
      ..checkResult = ConnectivityStatus.offline
      ..checkGate = null;
    final checksBefore = repository.checkCalls;

    await tester.tap(find.byType(ConnectivityBarContent));
    await tester.pump();
    expect(find.text('Reconnecting…'), findsOneWidget);
    await tester.pump(testRetryDwell * 2);
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);
    expect(repository.checkCalls, checksBefore + 1);
  });

  testWidgets('back online shows, holds, then collapses and gives the '
      'inset back', (tester) async {
    await pumpHost(tester);
    await report(tester, ConnectivityStatus.offline);
    repository.report(ConnectivityStatus.online);
    await tester.pump();
    await tester.pump();
    expect(find.text('Back online'), findsOneWidget);

    await tester.pump(testBackOnlineFor * 2);
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsNothing);
    expect(find.byType(ConnectivityBarContent), findsNothing);
    expect(pageInset(tester), 24);
  });

  testWidgets('a status change never rebuilds the routes below', (
    tester,
  ) async {
    await pumpHost(tester);
    final builds = pageBuilds.length;
    await report(tester, ConnectivityStatus.offline);
    repository.report(ConnectivityStatus.online);
    await tester.pump();
    await tester.pump(testBackOnlineFor * 2);
    await tester.pumpAndSettle();
    expect(pageBuilds.length, builds);
  });

  testWidgets('never over the splash', (tester) async {
    onSplash = true;
    await pumpHost(tester);
    await report(tester, ConnectivityStatus.offline);
    expect(find.text("You're offline"), findsNothing);

    onSplash = false;
    routes.value++;
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);
  });

  testWidgets('a read that failed in transport asks the host: a live check; '
      'the loads that failed together retry, one that fails again after its '
      'retry does not until the gap passed', (tester) async {
    var time = DateTime(2026, 9, 27, 12);
    await pumpHost(tester, now: () => time);
    final recheck = ConnectivityScope.recheckerOf(
      tester.element(find.text('page body')),
    )!;
    Future<ConnectionRecheck> ask({Duration after = Duration.zero}) async {
      time = time.add(after);
      final answer = recheck();
      await tester.pump();
      await tester.pump(testOfflineAfter * 2);
      await tester.pumpAndSettle();
      return answer;
    }

    repository.checkResult = ConnectivityStatus.offline;
    expect(await ask(), ConnectionRecheck.offline, reason: 'no retry');
    expect(repository.checkCalls, greaterThanOrEqualTo(1));

    repository.checkResult = ConnectivityStatus.online;
    expect(
      await ask(),
      ConnectionRecheck.retry,
      reason: 'reachable after all: load again',
    );
    expect(
      await ask(after: testOfflineAfter ~/ 2),
      ConnectionRecheck.retry,
      reason: 'a load that failed together with it goes too',
    );
    expect(
      await ask(after: testOfflineAfter),
      ConnectionRecheck.reachable,
      reason: 'failed again after its retry: the error, no loop',
    );
    expect(
      await ask(after: AppConstants.readRetryGap),
      ConnectionRecheck.retry,
      reason: 'the gap passed: a new wave',
    );
    await tester.pump(testBackOnlineFor * 2);
    await tester.pumpAndSettle();
  });

  testWidgets('the scope tells the page it is offline; a nudge shakes', (
    tester,
  ) async {
    await pumpHost(tester);
    final page = tester.element(find.text('page body'));
    expect(ConnectivityScope.readIsOffline(page), isFalse);
    await report(tester, ConnectivityStatus.offline);
    expect(ConnectivityScope.readIsOffline(page), isTrue);

    final shakeBefore = tester.widget<ShakeX>(find.byType(ShakeX)).shakeKey;
    ConnectivityScope.nudge(page);
    await tester.pump();
    expect(
      tester.widget<ShakeX>(find.byType(ShakeX)).shakeKey,
      isNot(shakeBefore),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('Arabic, right to left: icon on the start (right) side', (
    tester,
  ) async {
    _useLanguage('ar');
    await pumpHost(tester, direction: TextDirection.rtl);
    await report(tester, ConnectivityStatus.offline);
    expect(find.text('أنت غير متصل بالإنترنت'), findsOneWidget);
    final icon = tester.getCenter(find.byIcon(HeroIcons.offline));
    final title = tester.getCenter(find.text('أنت غير متصل بالإنترنت'));
    expect(icon.dx, greaterThan(title.dx));
  });

  testWidgets('1.3× text wraps without overflowing', (tester) async {
    tester.view.physicalSize = const Size(960, 1600); // a 320 dp phone
    await pumpHost(tester, textScale: 1.3);
    await report(tester, ConnectivityStatus.offline);
    expect(tester.takeException(), isNull);
    expect(find.text("You're offline"), findsOneWidget);
  });

  testWidgets('reduced motion: instant swaps, no running ticker', (
    tester,
  ) async {
    await pumpHost(tester, reducedMotion: true);
    repository
      ..checkResult = ConnectivityStatus.offline
      ..report(ConnectivityStatus.offline);
    await tester.pump();
    await tester.pump(testOfflineAfter * 2);
    await tester.pump();
    expect(find.text("You're offline"), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);

    repository.checkGate = null;
    repository.checkResult = ConnectivityStatus.offline;
    await tester.tap(find.byType(ConnectivityBarContent));
    await tester.pump();
    expect(find.text('Reconnecting…'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(testRetryDwell * 2);
  });

  testWidgets('a live region that announces offline and back online', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHost(tester);
    await report(tester, ConnectivityStatus.offline);
    final node = tester.getSemantics(find.byType(ConnectivityBarContent));
    expect(
      node,
      matchesSemantics(
        label: "You're offline",
        hint: 'Tap to check again',
        isLiveRegion: true,
        isButton: true,
        hasTapAction: true,
      ),
    );

    repository.report(ConnectivityStatus.online);
    await tester.pump();
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(ConnectivityBarContent)),
      matchesSemantics(label: 'Back online', isLiveRegion: true),
    );
    await tester.pump(testBackOnlineFor * 2);
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}
