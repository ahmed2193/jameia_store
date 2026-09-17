// Inbox page over a MaterialApp.router with fake use cases behind the real DI
// container shape (`sl<NotificationsCubit>()`), the en translations loaded,
// and the app-global UnreadNotificationsCubit provided above the router.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:jameia_mart/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:jameia_mart/src/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:jameia_mart/src/features/notifications/presentation/widgets/notification_time_text.dart';
import 'package:jameia_mart/src/features/notifications/presentation/widgets/notifications_empty_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGetNotificationsUseCase getNotifications;
  late FakeMarkNotificationReadUseCase markRead;
  late FakeMarkAllNotificationsReadUseCase markAllRead;
  late FakeWatchLiveNotificationsUseCase watchLive;
  late UnreadNotificationsCubit unread;

  final n1 = notification(id: 'n1', orderId: 'order-1');
  final n2 = notification(id: 'n2', isRead: true, ticketNumber: 'T-1');
  final page1 = feedOf([n1, n2], page: 1, total: 2, unreadCount: 3);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() {
    getNotifications = FakeGetNotificationsUseCase(Right(page1));
    markRead = FakeMarkNotificationReadUseCase(
      Right(n1.copyWith(isRead: true)),
    );
    markAllRead = FakeMarkAllNotificationsReadUseCase(const Right(1));
    watchLive = FakeWatchLiveNotificationsUseCase();
    unread = UnreadNotificationsCubit(
      getNotifications: FakeGetNotificationsUseCase(
        const Left(UnauthorizedFailure()),
      ),
      watchLive: FakeWatchLiveNotificationsUseCase(),
    );
    // The page resolves its cubit through the real container; only the
    // network behind it is faked.
    if (sl.isRegistered<NotificationsCubit>()) {
      sl.unregister<NotificationsCubit>();
    }
    sl.registerFactory(
      () => NotificationsCubit(
        getNotifications: getNotifications,
        markRead: markRead,
        markAllRead: markAllRead,
        watchLive: watchLive,
      ),
    );
  });

  tearDown(() async {
    await unread.close();
    if (!watchLive.controller.isClosed) await watchLive.controller.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: Routes.notifications,
      routes: [
        GoRoute(
          path: Routes.notifications,
          builder: (_, _) => const NotificationsPage(),
        ),
        GoRoute(
          path: Routes.orderTracking,
          builder: (_, state) =>
              Scaffold(body: Text('tracking:${state.extra}')),
        ),
        GoRoute(
          path: Routes.customerService,
          builder: (_, _) => const Scaffold(body: Text('support')),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: BlocProvider<UnreadNotificationsCubit>.value(
          value: unread,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await settle(tester);
    return router;
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 70));
  }

  testWidgets('renders the inbox and syncs the unread badge', (tester) async {
    await pumpPage(tester);

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.byType(NotificationTile), findsNWidgets(2));
    expect(find.text('Title n1'), findsOneWidget);
    expect(find.text('Body n2'), findsOneWidget);
    expect(find.text('3 unread'), findsOneWidget);
    expect(unread.state.unreadCount, 3);
    expect(getNotifications.calls.single.page, 1);
    await teardownApp(tester);
  });

  testWidgets(
    'tapping an order notification marks it read and opens tracking',
    (tester) async {
      final router = await pumpPage(tester);

      await tester.tap(find.text('Title n1'));
      await settle(tester);

      expect(markRead.calls.single.id, 'n1');
      expect(router.state.uri.path, Routes.orderTracking);
      expect(find.text('tracking:order-1'), findsOneWidget);
      await teardownApp(tester);
    },
  );

  testWidgets('a support notification opens customer service', (tester) async {
    final router = await pumpPage(tester);

    await tester.tap(find.text('Title n2'));
    await settle(tester);

    expect(markRead.calls, isEmpty, reason: 'already read');
    expect(router.state.uri.path, Routes.customerService);
    await teardownApp(tester);
  });

  testWidgets('mark all read shows the toast and clears the caption', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await settle(tester);

    expect(markAllRead.calls, 1);
    expect(find.text('All notifications marked as read'), findsOneWidget);
    expect(find.text('3 unread'), findsNothing);
    expect(unread.state.unreadCount, 0);
    await teardownApp(tester);
  });

  testWidgets('a live notification appears on top', (tester) async {
    await pumpPage(tester);

    watchLive.emit(notification(id: 'live'));
    await settle(tester);

    expect(find.text('Title live'), findsOneWidget);
    expect(find.text('4 unread'), findsOneWidget);
    expect(unread.state.unreadCount, 4);
    await teardownApp(tester);
  });

  testWidgets('an empty inbox shows the empty state', (tester) async {
    getNotifications.result = Right(feedOf([]));
    await pumpPage(tester);

    expect(find.byType(NotificationsEmptyView), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('a guest sees the sign-in prompt and can go to login', (
    tester,
  ) async {
    getNotifications.result = const Left(UnauthorizedFailure('Sign in'));
    final router = await pumpPage(tester);

    expect(find.text('Sign in to see your notifications'), findsOneWidget);
    await tester.tap(find.text('Log in or sign up'));
    await settle(tester);

    expect(router.state.uri.path, Routes.login);
    await teardownApp(tester);
  });

  testWidgets('a transport failure shows the localized error with retry', (
    tester,
  ) async {
    getNotifications.result = const Left(NetworkFailure());
    await pumpPage(tester);

    expect(find.textContaining('No internet connection'), findsOneWidget);
    getNotifications.result = Right(page1);
    await tester.tap(find.text('Retry'));
    await settle(tester);

    expect(find.byType(NotificationTile), findsNWidgets(2));
    await teardownApp(tester);
  });

  group('NotificationTimeText.format', () {
    final now = DateTime(2026, 9, 17, 15, 0);

    // `intl` separates the day period with U+202F (narrow no-break space).
    String plain(String text) => text.replaceAll(RegExp(r'\s'), ' ');

    test('same day → time only', () {
      expect(
        plain(
          NotificationTimeText.format(
            DateTime(2026, 9, 17, 10, 30),
            now: now,
            languageCode: 'en',
          ),
        ),
        '10:30 AM',
      );
    });

    test('same year → month day + time', () {
      expect(
        plain(
          NotificationTimeText.format(
            DateTime(2026, 3, 2, 9, 5),
            now: now,
            languageCode: 'en',
          ),
        ),
        'Mar 2 9:05 AM',
      );
    });

    test('earlier year → full date', () {
      expect(
        NotificationTimeText.format(
          DateTime(2025, 12, 31, 23, 59),
          now: now,
          languageCode: 'en',
        ),
        'Dec 31, 2025',
      );
    });

    test('an unknown locale falls back instead of throwing', () {
      expect(
        () => NotificationTimeText.format(
          DateTime(2026, 9, 17, 10, 30),
          now: now,
          languageCode: 'xx',
        ),
        returnsNormally,
      );
    });
  });
}
