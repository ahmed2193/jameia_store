// The core offline kit: RelativeAge plurals (English + the Arabic forms for
// 1, 2, 3–10, 11+), StaleDataNotice (fades in once, re-reads the age once a
// minute), ReconnectRefresh (once per reconnect epoch, after the jitter),
// HeroStateView.offline, and showFailureSnackBar (offline read failures
// only nudge the banner; an offline action says the input is kept).

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/constants/app_constants.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/domain/entities/connection_recheck.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/navigation/hero_snack_bar.dart';
import 'package:hero_mart/src/core/utils/relative_age.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/core/widgets/failure_view.dart';
import 'package:hero_mart/src/core/widgets/hero_state_view.dart';
import 'package:hero_mart/src/core/widgets/reconnect_refresh.dart';
import 'package:hero_mart/src/core/widgets/stale_age_pill.dart';
import 'package:hero_mart/src/core/widgets/stale_data_notice.dart';
import 'package:hero_mart/src/core/widgets/state_art.dart';
import 'package:hero_mart/src/core/domain/entities/data_freshness.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Map<String, dynamic> _en;
late Map<String, dynamic> _ar;

void _useLanguage(String code) {
  Intl.defaultLocale = code;
  Localization.load(
    Locale(code),
    translations: Translations(code == 'ar' ? _ar : _en),
    // As main.dart: the CLDR rules, so Arabic gets its few / many forms.
    ignorePluralRules: false,
  );
}

/// A random whose every draw is [value].
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;

  @override
  int nextInt(int max) => value.clamp(0, max - 1);

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

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

  setUp(() => _useLanguage('en'));

  final now = DateTime(2026, 9, 27, 12);
  String ago(Duration age) => RelativeAge.updated(now.subtract(age), now: now);

  group('RelativeAge', () {
    test('English', () {
      expect(ago(const Duration(seconds: 20)), 'Updated just now');
      expect(ago(const Duration(minutes: 1)), 'Updated 1 minute ago');
      expect(ago(const Duration(minutes: 12)), 'Updated 12 minutes ago');
      expect(ago(const Duration(hours: 1)), 'Updated 1 hour ago');
      expect(ago(const Duration(hours: 5)), 'Updated 5 hours ago');
      expect(ago(const Duration(days: 1)), 'Updated 1 day ago');
      expect(ago(const Duration(days: 3)), 'Updated 3 days ago');
    });

    test('a time in the future reads just now', () {
      expect(ago(const Duration(minutes: -30)), 'Updated just now');
    });

    test('Arabic plural forms', () {
      _useLanguage('ar');
      expect(ago(const Duration(minutes: 1)), 'آخر تحديث قبل دقيقة');
      expect(ago(const Duration(minutes: 2)), 'آخر تحديث قبل دقيقتين');
      expect(ago(const Duration(minutes: 5)), 'آخر تحديث قبل 5 دقائق');
      expect(ago(const Duration(minutes: 11)), 'آخر تحديث قبل 11 دقيقة');
      expect(ago(const Duration(hours: 2)), 'آخر تحديث قبل ساعتين');
      expect(ago(const Duration(days: 12)), 'آخر تحديث قبل 12 يوماً');
    });
  });

  group('StaleAgePill', () {
    testWidgets('shows the age and re-reads it once a minute', (tester) async {
      var clock = now;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaleAgePill(
              savedAt: now.subtract(const Duration(minutes: 3)),
              clock: () => clock,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Updated 3 minutes ago'), findsOneWidget);

      clock = now.add(const Duration(seconds: 50));
      await tester.pump(const Duration(seconds: 50));
      expect(find.text('Updated 3 minutes ago'), findsOneWidget);

      clock = now.add(const Duration(minutes: 1, seconds: 1));
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Updated 4 minutes ago'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('fades in once, not on a new age', (tester) async {
      Widget notice(DateTime savedAt) => MaterialApp(
        home: Scaffold(
          body: StaleAgePill(savedAt: savedAt, clock: () => now),
        ),
      );
      await tester.pumpWidget(notice(now));
      await tester.pumpAndSettle();
      await tester.pumpWidget(notice(now.subtract(const Duration(minutes: 9))));
      expect(tester.binding.transientCallbackCount, 0, reason: 'no re-fade');
      expect(find.text('Updated 9 minutes ago'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ConnectivityScope.confirmOnline', () {
    Future<bool> confirm(
      WidgetTester tester, {
      required bool offline,
      Future<bool> Function()? check,
    }) async {
      late BuildContext inside;
      await tester.pumpWidget(
        ConnectivityScope(
          isOffline: offline,
          reconnectEpoch: 0,
          onNudge: () {},
          checkOnline: check,
          child: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      );
      return ConnectivityScope.confirmOnline(inside);
    }

    testWidgets('online: yes, without a check', (tester) async {
      var checks = 0;
      final online = await confirm(
        tester,
        offline: false,
        check: () async {
          checks++;
          return false;
        },
      );

      expect(online, isTrue);
      expect(checks, 0);
    });

    testWidgets('offline: the live check decides', (tester) async {
      expect(
        await confirm(tester, offline: true, check: () async => true),
        isTrue,
      );
      expect(
        await confirm(tester, offline: true, check: () async => false),
        isFalse,
      );
      expect(
        await confirm(tester, offline: true),
        isFalse,
        reason: 'no checker: what the scope knows',
      );
    });

    testWidgets('outside a scope: yes', (tester) async {
      late BuildContext inside;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            inside = context;
            return const SizedBox();
          },
        ),
      );

      expect(await ConnectivityScope.confirmOnline(inside), isTrue);
    });
  });

  group('DataFreshness + StaleDataNotice', () {
    final saved = now.subtract(const Duration(minutes: 7));
    final fromCache = DataFreshness(fetchedAt: saved, fromCache: true);
    final fromNetwork = DataFreshness(fetchedAt: saved);

    test('stale: the device copy, or a failed refresh', () {
      expect(DataFreshness.none.isStale, isFalse);
      expect(fromCache.isStale, isTrue);
      expect(fromNetwork.isStale, isFalse);
      expect(fromNetwork.failed().isStale, isTrue);
      expect(DataFreshness.none.failed(), DataFreshness.none);
    });

    test('two reads shown together: stale when either is, dated by the '
        'older', () {
      final older = now.subtract(const Duration(hours: 3));
      final fresh = DataFreshness(fetchedAt: now);
      final copy = DataFreshness(fetchedAt: older, fromCache: true);

      expect(fresh.alongside(copy), copy);
      expect(copy.alongside(fresh), copy);
      expect(fresh.alongside(DataFreshness.none), fresh);
      expect(DataFreshness.none.alongside(fresh), fresh);
      expect(
        fresh.failed().alongside(DataFreshness(fetchedAt: older)),
        DataFreshness(fetchedAt: older, refreshFailed: true),
      );
    });

    test('the note: offline, or after the refresh failed', () {
      expect(fromCache.noticeVisible(offline: false), isFalse);
      expect(fromCache.noticeVisible(offline: true), isTrue);
      expect(fromCache.failed().noticeVisible(offline: false), isTrue);
      expect(fromNetwork.noticeVisible(offline: true), isFalse);
    });

    Widget scoped(DataFreshness freshness, {required bool offline}) =>
        MaterialApp(
          home: ConnectivityScope(
            isOffline: offline,
            reconnectEpoch: 0,
            onNudge: () {},
            child: Scaffold(body: StaleDataNotice(freshness: freshness)),
          ),
        );

    testWidgets('shows over the device copy only while offline', (
      tester,
    ) async {
      await tester.pumpWidget(scoped(fromCache, offline: false));
      expect(find.byType(StaleAgePill), findsNothing);
      await tester.pumpWidget(scoped(fromCache, offline: true));
      await tester.pumpAndSettle();
      expect(find.byType(StaleAgePill), findsOneWidget);
      // Fresh data: the note folds away (height + fade), then is gone.
      await tester.pumpWidget(scoped(fromNetwork, offline: true));
      await tester.pumpAndSettle();
      expect(find.byType(StaleAgePill), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ReconnectRefresh', () {
    Widget scoped(int epoch, VoidCallback onReconnected) => MaterialApp(
      home: ConnectivityScope(
        isOffline: false,
        reconnectEpoch: epoch,
        onNudge: () {},
        child: ReconnectRefresh(
          random: _FixedRandom(250),
          onReconnected: onReconnected,
          child: const Text('page'),
        ),
      ),
    );

    testWidgets('once per epoch, after the jitter; never on mount', (
      tester,
    ) async {
      var calls = 0;
      void count() => calls++;
      await tester.pumpWidget(scoped(0, count));
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 0);

      await tester.pumpWidget(scoped(1, count));
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, 0, reason: 'still in the jitter');
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, 1);

      await tester.pumpWidget(scoped(1, count));
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1, reason: 'same epoch: nothing');
    });

    testWidgets('unmounted during the jitter → no call', (tester) async {
      var calls = 0;
      await tester.pumpWidget(scoped(0, () => calls++));
      await tester.pumpWidget(scoped(1, () => calls++));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 0);
    });
  });

  testWidgets('HeroStateView.offline: calm copy + try again', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HeroStateView.offline(onRetry: () => retries++)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No connection'), findsOneWidget);
    expect(
      find.text(
        "Check your Wi-Fi or mobile data. This page loads as soon as you're "
        'back online.',
      ),
      findsOneWidget,
    );
    // The offline plate, not a Material glyph.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is StateArt && widget.asset == HeroAssets.stateOffline,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(HeroIcons.offline), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  group('showFailureSnackBar', () {
    Future<(BuildContext, List<int>)> host(
      WidgetTester tester, {
      required bool offline,
    }) async {
      final nudges = <int>[];
      late BuildContext inner;
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectivityScope(
            isOffline: offline,
            reconnectEpoch: 0,
            onNudge: () => nudges.add(1),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  inner = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      return (inner, nudges);
    }

    testWidgets('offline read failure: no snack bar, one nudge', (
      tester,
    ) async {
      final (context, nudges) = await host(tester, offline: true);
      showFailureSnackBar(context, const NetworkFailure());
      showFailureSnackBar(context, const TimeoutFailure());
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
      expect(nudges, hasLength(2));
    });

    testWidgets('offline action failure: "changes are kept" + nudge', (
      tester,
    ) async {
      final (context, nudges) = await host(tester, offline: true);
      showFailureSnackBar(context, const NetworkFailure(), action: true);
      await tester.pump();
      expect(
        find.text(
          "You're offline. Your changes are kept, try again when you're back.",
        ),
        findsOneWidget,
      );
      expect(nudges, hasLength(1));
    });

    testWidgets('a read that failed in transport says nothing before the app '
        'knows it is offline (the check and the banner speak)', (tester) async {
      final (context, nudges) = await host(tester, offline: false);
      showFailureSnackBar(context, const NetworkFailure());
      showFailureSnackBar(context, const TimeoutFailure());
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
      expect(nudges, isEmpty);
    });

    testWidgets('online, an action that timed out: its own message', (
      tester,
    ) async {
      final (context, nudges) = await host(tester, offline: false);
      showFailureSnackBar(context, const TimeoutFailure(), action: true);
      await tester.pump();
      expect(
        find.text('The request timed out. Please try again.'),
        findsOneWidget,
      );
      expect(nudges, isEmpty);
    });

    testWidgets('a server failure is shown even offline', (tester) async {
      final (context, _) = await host(tester, offline: true);
      showFailureSnackBar(context, const ServerFailure('Out of stock'));
      await tester.pump();
      expect(find.text('Out of stock'), findsOneWidget);
    });
  });

  group('FailureView', () {
    const checking = 'Checking your connection…';
    const noConnection = 'No connection';

    Future<void> pump(
      WidgetTester tester, {
      required Failure failure,
      required bool offline,
      Future<ConnectionRecheck> Function()? recheck,
      VoidCallback? onRetry,
    }) => tester.pumpWidget(
      MaterialApp(
        home: ConnectivityScope(
          isOffline: offline,
          reconnectEpoch: 0,
          onNudge: () {},
          recheckForRetry: recheck,
          child: Scaffold(
            body: FailureView(failure: failure, onRetry: onRetry ?? () {}),
          ),
        ),
      ),
    );

    testWidgets('known offline: "No connection" at once, no check', (
      tester,
    ) async {
      var checks = 0;
      await pump(
        tester,
        failure: const NetworkFailure(),
        offline: true,
        recheck: () async {
          checks++;
          return ConnectionRecheck.retry;
        },
      );
      await tester.pump();

      expect(find.text(noConnection), findsOneWidget);
      expect(find.text(checking), findsNothing);
      expect(checks, 0);
    });

    testWidgets('not known offline: "Checking your connection…" first, never '
        '"No connection" straight away; still unreachable → "No connection", '
        'no retry', (tester) async {
      var checks = 0;
      var retries = 0;
      await pump(
        tester,
        failure: const NetworkFailure(),
        offline: false,
        recheck: () async {
          checks++;
          return ConnectionRecheck.offline;
        },
        onRetry: () => retries++,
      );
      await tester.pump();

      expect(find.text(checking), findsOneWidget);
      expect(find.text(noConnection), findsNothing);
      expect(checks, 1);

      await tester.pump(AppConstants.offlineDebounce ~/ 2);
      expect(
        find.text(checking),
        findsOneWidget,
        reason: 'held until the banner has had time to confirm',
      );

      await tester.pump(AppConstants.offlineDebounce);
      expect(find.text(noConnection), findsOneWidget);
      expect(retries, 0);
    });

    testWidgets('the check reaches the server: the screen loads again by '
        'itself, once', (tester) async {
      var retries = 0;
      await pump(
        tester,
        failure: const NetworkFailure(),
        offline: false,
        recheck: () async => ConnectionRecheck.retry,
        onRetry: () => retries++,
      );
      await tester.pump();
      await tester.pump(AppConstants.offlineDebounce);

      expect(retries, 1);
    });

    testWidgets('the connection is there but the store failed again: the '
        'error + retry, never "No connection"', (tester) async {
      var retries = 0;
      await pump(
        tester,
        failure: const NetworkFailure(),
        offline: false,
        recheck: () async => ConnectionRecheck.reachable,
        onRetry: () => retries++,
      );
      await tester.pump();
      await tester.pump(AppConstants.offlineDebounce);

      expect(find.text(noConnection), findsNothing);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(retries, 0, reason: 'no loop: the customer retries');
    });

    testWidgets('a timeout: "No connection" once the app knows it is '
        'offline, else the error — no check either way', (tester) async {
      var checks = 0;
      Future<ConnectionRecheck> recheck() async {
        checks++;
        return ConnectionRecheck.retry;
      }

      await pump(
        tester,
        failure: const TimeoutFailure(),
        offline: true,
        recheck: recheck,
      );
      await tester.pump();
      expect(find.text(noConnection), findsOneWidget);

      await pump(
        tester,
        failure: const TimeoutFailure(),
        offline: false,
        recheck: recheck,
      );
      // The verdict swap cross-fades.
      await tester.pumpAndSettle();
      expect(find.text(noConnection), findsNothing);
      expect(find.text(checking), findsNothing);
      expect(checks, 0);
    });

    testWidgets('the app turning offline during the check shows "No '
        'connection" at once', (tester) async {
      final never = Completer<ConnectionRecheck>();
      await pump(
        tester,
        failure: const NetworkFailure(),
        offline: false,
        recheck: () => never.future,
      );
      await tester.pump();
      expect(find.text(checking), findsOneWidget);

      await pump(
        tester,
        failure: const NetworkFailure(),
        offline: true,
        recheck: () => never.future,
      );
      await tester.pump();
      expect(find.text(noConnection), findsOneWidget);
      await tester.pump(AppConstants.offlineDebounce * 2);
    });

    testWidgets('outside the banner host (nothing can check): "No connection" '
        'at once', (tester) async {
      await pump(tester, failure: const NetworkFailure(), offline: false);
      await tester.pump();

      expect(find.text(noConnection), findsOneWidget);
      expect(find.text(checking), findsNothing);
    });

    testWidgets('any other failure: its message, no check', (tester) async {
      var checks = 0;
      await pump(
        tester,
        failure: const ServerFailure('Out of stock'),
        offline: false,
        recheck: () async {
          checks++;
          return ConnectionRecheck.retry;
        },
      );
      await tester.pump();

      expect(find.text('Out of stock'), findsOneWidget);
      expect(checks, 0);
    });
  });
}
