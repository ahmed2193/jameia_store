// The Mine tab over the real overview cubit (offline catalogue, through DI)
// and hand-made app-global cubits: the guest, signed-in and Pro member
// headers, every menu entry and stat opening its screen, the Assistant row
// following the store flag, the collapsing header, the one ambient shine,
// value changes (wallet roll, badge pop) and an Arabic small phone at text
// × 1.3. The shine loops while motion is on, so the tests advance fixed
// frames instead of settling.
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/change_bump.dart';
import 'package:hero_mart/src/core/motion/rolling_number.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/core/widgets/light_sweep_band.dart';
import 'package:hero_mart/src/features/account/presentation/pages/mine_page.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_header_compact_title.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_points_stat.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_pro_badge.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_scan_action.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_stats_card.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_unread_badge.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_wallet_stat.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_availability.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_availability_usecase.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:hero_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import '../notifications/notifications_test_fakes.dart';
import '../store_mode/pro_status_fakes.dart';
import '../../core/motion/rolling_test_finders.dart';
import '../../core/network/network_test_fakes.dart';

class _Availability implements GetAssistantAvailabilityUseCase {
  _Availability(this.enabled);

  final bool enabled;

  @override
  Future<Either<Failure, AssistantAvailability>> call(NoParams params) async =>
      Right(AssistantAvailability(enabled: enabled));
}

const AuthCustomerEntity _member = AuthCustomerEntity(
  id: 'c1',
  phone: '+96550001122',
  nameEn: 'Ahmed Al-Fawaly',
  nameAr: 'Ahmed Al-Fawaly',
  walletFils: 12500,
  loyaltyPoints: 340,
  isPro: true,
);

const AuthCustomerEntity _regular = AuthCustomerEntity(
  id: 'c2',
  phone: '+96550003344',
  nameEn: 'Sara',
  walletFils: 2000,
);

/// Every stub destination renders its own path, so a tap can be checked.
const List<String> _destinations = [
  Routes.login,
  Routes.profileEdit,
  Routes.mineDeliveryCode,
  Routes.orders,
  Routes.addressList,
  Routes.myCoupons,
  Routes.wallet,
  Routes.loyalty,
  Routes.proMembership,
  Routes.notifications,
  Routes.assistant,
  Routes.customerService,
  Routes.mineSettings,
  Routes.mineAbout,
];

void main() {
  late AuthSessionCubit session;
  late UnreadNotificationsCubit unread;
  late FakeProStatusRepository proRepository;
  late ProStatusCubit proStatus;
  final availabilities = <AssistantAvailabilityCubit>[];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    // The Pro row's "Ends Oct 17".
    await initializeDateFormatting('en');
    registerFakeNetworkInfo();
    await setupServiceLocator();
  });

  setUp(() {
    session = AuthSessionCubit(
      restoreSession: FakeRestoreSessionUseCase(const Right(null)),
      logout: FakeLogoutUseCase(),
      watchExpiry: FakeWatchSessionExpiryUseCase(),
      getCachedCustomer: FakeGetCachedCustomerUseCase(),
      saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
      clearCachedCustomer: FakeClearCachedCustomerUseCase(),
    );
    unread = UnreadNotificationsCubit(
      getNotifications: FakeGetNotificationsUseCase(
        const Left(UnauthorizedFailure()),
      ),
    );
    // Idle (standing unknown: no Pro chip) until a test settles it.
    proRepository = FakeProStatusRepository();
    proStatus = buildProStatus(proRepository);
  });

  tearDown(() async {
    await session.close();
    await unread.close();
    await proStatus.close();
    for (final cubit in availabilities) {
      await cubit.close();
    }
    availabilities.clear();
  });

  Future<void> frames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps the Mine page as the router's home over stub destinations. A tall
  /// phone by default, so every card is on screen.
  Future<GoRouter> pump(
    WidgetTester tester, {
    bool assistant = false,
    bool reducedMotion = false,
    Locale locale = const Locale('en'),
    Size logicalSize = const Size(430, 2400),
    double textScale = 1,
    Widget Function(Widget page)? host,
  }) async {
    Intl.defaultLocale = locale.languageCode;
    addTearDown(() => Intl.defaultLocale = 'en');
    tester.view.physicalSize = logicalSize * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final availability = AssistantAvailabilityCubit(
      getAvailability: _Availability(assistant),
    );
    availabilities.add(availability);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => host?.call(const MinePage()) ?? const MinePage(),
        ),
        for (final path in _destinations)
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('route:$path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await availability.ensureLoaded();
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: locale,
          saveLocale: false,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthSessionCubit>.value(value: session),
              BlocProvider<UnreadNotificationsCubit>.value(value: unread),
              BlocProvider<AssistantAvailabilityCubit>.value(
                value: availability,
              ),
              BlocProvider<ProStatusCubit>.value(value: proStatus),
            ],
            child: Builder(
              builder: (context) => MaterialApp.router(
                theme: AppTheme.light,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: reducedMotion,
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: child!,
                ),
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      // Lets the translation asset load for real.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await frames(tester);
    return router;
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Finder inStats(String text) => find.descendant(
    of: find.byType(MineStatsCard),
    matching: find.text(text),
  );

  /// A number in the stats card (they roll, one Text per digit).
  Finder rolledInStats(String text) => find.descendant(
    of: find.byType(MineStatsCard),
    matching: findRolled(text),
  );

  final wallet = find.descendant(
    of: find.byType(MineWalletStat),
    matching: find.byType(RollingNumber),
  );

  testWidgets('guest: the sign-in header opens login; no assistant row', (
    tester,
  ) async {
    proStatus.stop();
    await pump(tester);

    expect(find.text('Sign in or register'), findsNWidgets(2));
    expect(
      find.text('Track orders, earn points and save addresses'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Hero Assistant'), findsNothing);
    expect(find.text('PRO'), findsNothing);
    expect(find.text('Active'), findsNothing);
    // Pro is on offer: the Pro row invites the guest in.
    expect(find.text('Join'), findsOneWidget);
    // A guest's balances are zero; the overview counts still show.
    expect(tester.widget<RollingNumber>(wallet).value, 0);
    expect(
      find.descendant(
        of: find.byType(MinePointsStat),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sign in'));
    await frames(tester, 5);
    expect(find.text('route:${Routes.login}'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('member: name, phone, PRO pill, balances, Active, assistant', (
    tester,
  ) async {
    session.signedIn(_member);
    proRepository.subscription = const Right(
      ProSubscription(
        id: 's1',
        planId: 'monthly',
        status: ProSubscriptionStatus.active,
      ),
    );
    await proStatus.start(_member);
    await pump(tester, assistant: true);

    // The open header and the (hidden) collapsed bar both carry the name.
    expect(find.text('Ahmed Al-Fawaly'), findsNWidgets(2));
    expect(find.text('+96550001122'), findsOneWidget);
    expect(find.byType(MineProBadge), findsOneWidget);
    // No renewal date on this subscription: the plain "Active".
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Join'), findsNothing);
    expect(find.text('Hero Assistant'), findsOneWidget);
    expect(tester.widget<RollingNumber>(wallet).value, 12.5);
    expect(rolledInStats('340'), findsOneWidget);

    await tester.tap(find.text('+96550001122'));
    await frames(tester, 5);
    expect(find.text('route:${Routes.profileEdit}'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('the Pro row follows the standing: ends on a date, or rejoin', (
    tester,
  ) async {
    session.signedIn(_member);
    proRepository.subscription = Right(
      ProSubscription(
        id: 's1',
        planId: 'monthly',
        status: ProSubscriptionStatus.cancelled,
        cancelAtPeriodEnd: true,
        currentPeriodEnd: DateTime(2026, 10, 17, 12),
      ),
    );
    await proStatus.start(_member);
    await pump(tester);
    expect(find.text('Ends Oct 17'), findsOneWidget);
    await teardownApp(tester);

    session.signedIn(_regular);
    proRepository.subscription = Right(
      ProSubscription(
        id: 's1',
        planId: 'monthly',
        status: ProSubscriptionStatus.expired,
        currentPeriodEnd: DateTime(2026, 9, 17, 12),
      ),
    );
    await proStatus.start(_regular);
    await pump(tester);
    expect(find.text('Rejoin'), findsOneWidget);
    expect(find.text('Join'), findsNothing);
    await teardownApp(tester);
  });

  testWidgets('every menu row and stat opens its screen', (tester) async {
    session.signedIn(_regular);
    final router = await pump(tester, assistant: true);

    final rows = <String, String>{
      'My orders': Routes.orders,
      'Addresses': Routes.addressList,
      'Loyalty points': Routes.loyalty,
      'Hero Pro': Routes.proMembership,
      'Notifications': Routes.notifications,
      'Hero Assistant': Routes.assistant,
      'Customer service': Routes.customerService,
      'Settings': Routes.mineSettings,
      'About': Routes.mineAbout,
      'Delivery code': Routes.mineDeliveryCode,
    };
    final stats = <String, String>{
      'Wallet': Routes.wallet,
      'Points': Routes.loyalty,
      'Coupons': Routes.myCoupons,
    };
    Future<void> openAndBack(Finder target, String route) async {
      await tester.tap(target);
      await frames(tester, 5);
      expect(find.text('route:$route'), findsOneWidget, reason: route);
      router.pop();
      await frames(tester, 5);
    }

    for (final entry in rows.entries) {
      await openAndBack(find.text(entry.key).last, entry.value);
    }
    for (final entry in stats.entries) {
      await openAndBack(inStats(entry.key), entry.value);
    }
    // Wallet and coupons also have their own rows.
    await openAndBack(find.text('Wallet').last, Routes.wallet);
    await openAndBack(find.text('Coupons').last, Routes.myCoupons);
    await openAndBack(find.byType(MineScanAction), Routes.mineDeliveryCode);

    await teardownApp(tester);
  });

  testWidgets('balances change in place; the badge bumps only on a change', (
    tester,
  ) async {
    session.signedIn(_regular);
    unread.set(3);
    await pump(tester);

    // The inbox row comes before customer service (which has its own).
    ScaleTransition badgeScale() => tester.widget<ScaleTransition>(
      find
          .descendant(
            of: find
                .descendant(
                  of: find
                      .byWidgetPredicate(
                        (w) => w is MineUnreadBadge && w.count > 0,
                      )
                      .first,
                  matching: find.byType(ChangeBump),
                )
                .first,
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    // Already on screen when the tab opened: no pop.
    expect(badgeScale().scale.value, 1);

    unread.set(120);
    // The emit reaches the menu in a microtask: with nothing else animating,
    // the first pump only flushes it, the second builds the bump's start.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // One bump (1 → 1.15 → 1), never a regrow from nothing.
    expect(badgeScale().scale.value, greaterThan(1));
    await frames(tester, 5);
    expect(badgeScale().scale.value, 1);
    expect(findRolled('99+'), findsOneWidget);

    session.updateCustomer(
      const AuthCustomerEntity(
        id: 'c2',
        phone: '+96550003344',
        nameEn: 'Sara',
        walletFils: 4750,
        loyaltyPoints: 60,
      ),
    );
    await frames(tester);
    expect(tester.widget<RollingNumber>(wallet).value, 4.75);
    expect(rolledInStats('60'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('the header collapses: the compact name fades in', (
    tester,
  ) async {
    session.signedIn(_member);
    await pump(tester, logicalSize: const Size(390, 844));

    Color compactInk() => tester
        .widget<Text>(
          find.descendant(
            of: find.byType(MineHeaderCompactTitle),
            matching: find.byType(Text),
          ),
        )
        .style!
        .color!;
    expect(compactInk().a, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await frames(tester, 5);
    expect(compactInk().a, 1);
    // The pinned bar keeps the scan action on screen.
    expect(find.byType(MineScanAction).hitTestable(), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('one ambient shine at most: a member\'s PRO pill', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(LightSweepBand), findsNothing);
    await teardownApp(tester);

    session.signedIn(_member);
    await pump(tester);
    expect(find.byType(LightSweepBand), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MineProBadge),
        matching: find.byType(LightSweepBand),
      ),
      findsOneWidget,
    );
    await teardownApp(tester);
  });

  testWidgets('reduced motion: no shine, no entrance transitions', (
    tester,
  ) async {
    session.signedIn(_member);
    await pump(tester, reducedMotion: true);

    expect(find.byType(LightSweepBand), findsNothing);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Help & settings'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('builds nothing until its tab is first on screen', (
    tester,
  ) async {
    var index = 0;
    late StateSetter select;
    await pump(
      tester,
      host: (page) => StatefulBuilder(
        builder: (context, setState) {
          select = setState;
          return IndexedStack(index: index, children: [const SizedBox(), page]);
        },
      ),
    );
    expect(find.text('Sign in or register'), findsNothing);

    // Opening the tab creates the overview cubit, whose catalogue read
    // needs real async here.
    await tester.runAsync(() async {
      select(() => index = 1);
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await frames(tester);
    expect(find.text('Sign in or register'), findsNWidgets(2));

    // Back to another tab: the page is kept (hidden) as it was.
    select(() => index = 0);
    await frames(tester, 2);
    expect(
      find.text('Sign in or register', skipOffstage: false),
      findsNWidgets(2),
    );

    await teardownApp(tester);
  });

  testWidgets('Arabic small phone at text x1.3 lays out cleanly', (
    tester,
  ) async {
    session.signedIn(_member);
    proRepository.subscription = const Right(
      ProSubscription(
        id: 's1',
        planId: 'monthly',
        status: ProSubscriptionStatus.active,
      ),
    );
    await proStatus.start(_member);
    unread.set(120);
    await pump(
      tester,
      assistant: true,
      locale: const Locale('ar'),
      logicalSize: const Size(360, 640),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    expect(findRolled('99+'), findsOneWidget);
    expect(find.text('مفعّلة'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await frames(tester, 5);
    expect(tester.takeException(), isNull);

    await teardownApp(tester);
  });

  testWidgets('Arabic guest at text x1.3 lays out cleanly', (tester) async {
    await pump(
      tester,
      locale: const Locale('ar'),
      logicalSize: const Size(360, 640),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('تسجيل الدخول'), findsOneWidget);

    await teardownApp(tester);
  });
}
