// The Pro paywall over real cubits whose repository is faked: what a guest,
// a signed-in customer and a member see (plan tabs, the best-value chip, the
// per-month price, the CTA, the account strip, the member card), switching
// plans, subscribing (the welcome sheet), the brand rows, the error view's
// retry, and an Arabic small phone at text × 1.3. The paywall loops a few
// ambient animations, so motion-on tests advance fixed frames instead of
// settling.
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/routes/route_args/login_args.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/brand_entity.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/pro_membership_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/motion_beat.dart';
import 'package:hero_mart/src/core/widgets/stale_age_pill.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:hero_mart/src/features/store_mode/domain/repositories/pro_membership_repository.dart';
import 'package:hero_mart/src/features/store_mode/domain/usecases/cancel_pro_subscription_usecase.dart';
import 'package:hero_mart/src/features/store_mode/domain/usecases/get_pro_brands_usecase.dart';
import 'package:hero_mart/src/features/store_mode/domain/usecases/subscribe_to_pro_usecase.dart';
import 'package:hero_mart/src/features/store_mode/domain/usecases/watch_pro_program_usecase.dart';
import 'package:hero_mart/src/features/store_mode/domain/usecases/watch_pro_subscription_usecase.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_brands_cubit.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_membership_cubit.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'package:hero_mart/src/features/store_mode/presentation/widgets/pro_join_button.dart';
import 'package:hero_mart/src/features/store_mode/presentation/widgets/pro_membership_body.dart';
import 'package:hero_mart/src/features/store_mode/presentation/widgets/pro_outcome_listener.dart';
import 'package:hero_mart/src/features/store_mode/presentation/widgets/pro_status_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/snapshot_test_fakes.dart';
import '../../core/motion/rolling_test_finders.dart';
import '../auth/auth_test_fakes.dart';
import 'pro_status_fakes.dart';

/// The live programme (2026-09): Monthly 2.999 KD, Annual 24.999 KD.
const ProProgram _program = ProProgram(
  enabled: true,
  perks: ProPerks(freeDelivery: true, pointsMultiplier: 2, discountPercent: 5),
  plans: [
    ProPlan(id: 'monthly', name: 'Monthly', priceFils: 2999, sortOrder: 1),
    ProPlan(
      id: 'annual',
      name: 'Annual',
      interval: ProBillingInterval.year,
      priceFils: 24999,
      sortOrder: 2,
    ),
  ],
);

const AuthCustomerEntity _customer = AuthCustomerEntity(
  id: '507f1f77bcf86cd799439011',
  phone: '+96512345678',
  nameEn: 'Ahmed',
  loyaltyPoints: 120,
);

const Map<String, List<String>> _fonts = {
  'Hero': ['Hero-Regular.otf', 'Hero-Medium.otf', 'Hero-Bold.otf'],
  'NotoSansArabicUI': [
    'NotoSansArabicUI-Regular.ttf',
    'NotoSansArabicUI-Medium.ttf',
    'NotoSansArabicUI-Bold.ttf',
  ],
};

class _FakeRepository implements ProMembershipRepository {
  Either<Failure, ProProgram> program = const Right(_program);
  Either<Failure, ProSubscription?> subscription = const Left(
    UnauthorizedFailure(),
  );
  Either<Failure, List<BrandEntity>> brands = const Right(<BrandEntity>[]);
  Either<Failure, ProSubscription> subscribeResult = const Left(
    NetworkFailure(),
  );
  int programCalls = 0;

  /// The device copies the page paints first (none by default).
  ProProgram? savedProgram;
  ProSubscription? savedSubscription;

  @override
  Future<Either<Failure, ProProgram>> getProgram() async {
    programCalls++;
    return program;
  }

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() async =>
      subscription;

  @override
  Stream<DataSnapshot<ProProgram>> watchProgram({bool forceRefresh = false}) =>
      networkRead(getProgram(), saved: forceRefresh ? null : savedProgram);

  @override
  Stream<DataSnapshot<ProSubscription?>> watchSubscription({
    bool forceRefresh = false,
  }) => networkRead(
    getSubscription(),
    saved: forceRefresh ? null : savedSubscription,
  );

  @override
  Future<Either<Failure, ProSubscription>> subscribe(String planId) async =>
      subscribeResult;

  @override
  Future<Either<Failure, ProSubscription>> cancel() async =>
      const Left(NetworkFailure());

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async => brands;
}

void main() {
  late _FakeRepository repository;
  late ProMembershipCubit membership;
  late ProBrandsCubit brands;
  late AuthSessionCubit session;

  /// What the login stub was opened with (`null` until it is).
  Object? loginExtra;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    // The app's real fonts instead of the test font's 1 em squares, so the
    // small-phone check measures text the way a device does.
    for (final entry in _fonts.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
  });

  setUp(() {
    loginExtra = null;
    repository = _FakeRepository();
    membership = ProMembershipCubit(
      WatchProProgramUseCase(repository),
      WatchProSubscriptionUseCase(repository),
      SubscribeToProUseCase(repository),
      CancelProSubscriptionUseCase(repository),
    );
    brands = ProBrandsCubit(GetProBrandsUseCase(repository));
    session = AuthSessionCubit(
      restoreSession: FakeRestoreSessionUseCase(const Right(null)),
      logout: FakeLogoutUseCase(),
      watchExpiry: FakeWatchSessionExpiryUseCase(),
      getCachedCustomer: FakeGetCachedCustomerUseCase(),
      saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
      clearCachedCustomer: FakeClearCachedCustomerUseCase(),
    );
  });

  tearDown(() async {
    await membership.close();
    await brands.close();
    await session.close();
  });

  /// Plays every entrance / count-up / sheet transition to its end. The
  /// hero's float and glow, the brand rows and the member card's sheen loop
  /// forever while motion is on, so this advances fixed frames instead of
  /// `pumpAndSettle`.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Loads both cubits, then pumps the body under the page's outcome
  /// listener (a tall phone by default). [reducedMotion] turns every loop
  /// off (the brand rows only move by hand).
  Future<void> pump(
    WidgetTester tester, {
    bool reducedMotion = false,
    Locale locale = const Locale('en'),
    Size logicalSize = const Size(540, 1300),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = logicalSize * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await membership.load();
    await brands.load();
    // The confirm dialog and the welcome sheet close through go_router; the
    // login stub records what it was opened with.
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: ProOutcomeListener(child: ProMembershipBody()),
          ),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, state) {
            loginExtra = state.extra;
            return const Scaffold(body: Text('route:login'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: locale,
          saveLocale: false,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ProMembershipCubit>.value(value: membership),
              BlocProvider<ProBrandsCubit>.value(value: brands),
              BlocProvider<AuthSessionCubit>.value(value: session),
            ],
            child: Builder(
              builder: (context) => MaterialApp.router(
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
    await settle(tester);
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('guest: the plans, the saving chip, sign in to join', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    expect(find.text('Save 31%'), findsOneWidget);
    // Opens on the best value: the annual plan, spread per month.
    expect(find.text('A whole year'), findsOneWidget);
    expect(find.text('Hey there'), findsOneWidget);
    expect(findRolled('KD 2.083 / month'), findsOneWidget);
    expect(find.text('Billed yearly at KD 24.999'), findsOneWidget);
    expect(find.text('Sign in to join'), findsOneWidget);
    expect(find.text('Have an account?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Terms apply'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('signed in: join the selected plan; a tab switches it', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository.subscription = const Right(null);
    await pump(tester);

    expect(find.text('Hey, Ahmed'), findsOneWidget);
    expect(findRolled('You have 120 points'), findsOneWidget);
    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('Join for KD 24.999 / year'), findsOneWidget);
    expect(findRolled('KD 2.083 / month'), findsOneWidget);

    await tester.tap(find.text('Monthly'));
    await settle(tester);

    expect(membership.state.selectedPlanId, 'monthly');
    expect(find.text('Join for KD 2.999 / month'), findsOneWidget);
    expect(findRolled('KD 2.999 / month'), findsOneWidget);
    expect(find.text('Billed monthly'), findsOneWidget);
    expect(find.text('Every order,'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('a plan switch moves in order (B2-03): the thumb answers '
      'the tap, the price and the button a beat later, the hero last', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository.subscription = const Right(null);
    await pump(tester);
    expect(find.text('A whole year'), findsOneWidget);

    await tester.tap(find.text('Monthly'));
    await tester.pump();
    expect(membership.state.selectedPlanId, 'monthly');
    // The thumb is on its way; the price, the button and the hero wait.
    expect(tester.hasRunningAnimations, isTrue);
    expect(find.text('Billed yearly at KD 24.999'), findsOneWidget);
    expect(find.text('Join for KD 24.999 / year'), findsOneWidget);
    expect(find.text('Every order,'), findsNothing);

    await tester.pump(MotionBeat.second);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Billed monthly'), findsOneWidget);
    expect(find.text('Join for KD 2.999 / month'), findsOneWidget);
    expect(find.text('A whole year'), findsOneWidget);
    expect(find.text('Every order,'), findsNothing);

    await tester.pump(MotionBeat.third - MotionBeat.second);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Every order,'), findsOneWidget);
    await settle(tester);
    expect(find.text('A whole year'), findsNothing);
    expect(findRolled('KD 2.999 / month'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('member: the member card and cancel renewal, no CTA', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository.subscription = Right(
      ProSubscription(
        id: 'sub1',
        planId: 'monthly',
        planName: 'Monthly',
        priceFils: 2999,
        status: ProSubscriptionStatus.active,
        currentPeriodEnd: DateTime(2026, 10, 17, 12),
      ),
    );
    await pump(tester);

    expect(find.text("You're a Pro member"), findsOneWidget);
    // The member card: the programme, the renewal date, the hint.
    expect(find.text('Hero Pro'), findsOneWidget);
    expect(find.text('Renews on Sat, Oct 17, 2026'), findsOneWidget);
    expect(find.text('Your member card for every order'), findsOneWidget);
    expect(find.text('Cancel renewal'), findsOneWidget);
    expect(find.byType(ProJoinButton), findsNothing);
    expect(find.text('Cancel anytime'), findsNothing);
    expect(find.text('Terms apply'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('brand rows: one tile per brand, by hand under reduced motion', (
    tester,
  ) async {
    repository.brands = const Right([
      BrandEntity(id: 'b1', slug: 'almarai', name: 'Almarai'),
      BrandEntity(id: 'b2', slug: 'kdd', name: 'KDD'),
    ]);
    await pump(tester, reducedMotion: true);

    expect(find.text('Everything you need,'), findsOneWidget);
    expect(find.bySemanticsLabel('Almarai'), findsWidgets);
    expect(find.text('K'), findsWidgets);
    expect(find.text('Browse all brands'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('first load fails → the error view; retry loads the paywall', (
    tester,
  ) async {
    repository.program = const Left(NetworkFailure());
    await pump(tester);

    // Nothing saved and no connection: the calm offline state.
    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Monthly'), findsNothing);

    repository.program = const Right(_program);
    await tester.tap(find.text('Retry'));
    await settle(tester);

    expect(repository.programCalls, 2);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Sign in to join'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('a saved page whose refresh failed: the paywall + the note', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository
      ..savedProgram = _program
      ..savedSubscription = ProSubscription(
        id: 'sub1',
        planId: 'monthly',
        planName: 'Monthly',
        priceFils: 2999,
        status: ProSubscriptionStatus.active,
        currentPeriodEnd: DateTime(2026, 10, 17, 12),
      )
      ..program = const Left(NetworkFailure())
      ..subscription = const Left(NetworkFailure());
    await pump(tester);

    expect(find.text("You're a Pro member"), findsOneWidget);
    expect(find.byType(StaleAgePill), findsOneWidget);
    expect(find.text('No connection'), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('Arabic, 360×640, text × 1.3: every section lays out', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository
      ..subscription = const Right(null)
      ..brands = const Right([
        BrandEntity(id: 'b1', slug: 'almarai', name: 'المراعي'),
      ]);
    await pump(
      tester,
      reducedMotion: true,
      locale: const Locale('ar'),
      logicalSize: const Size(360, 640),
      textScale: 1.3,
    );

    expect(
      Directionality.of(tester.element(find.byType(ProMembershipBody))),
      TextDirection.rtl,
    );
    expect(find.text('وفّر 31٪'), findsOneWidget);
    // Scrolls down to the last perk card: nothing overflowed on the way.
    await tester.dragUntilVisible(
      find.text('أسعار الأعضاء'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('أسعار الأعضاء'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await teardownApp(tester);
  });

  testWidgets('subscribing: confetti, then the welcome sheet that closes', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository
      ..subscription = const Right(null)
      ..subscribeResult = Right(
        ProSubscription(
          id: 'sub1',
          planId: 'annual',
          planName: 'Annual',
          interval: ProBillingInterval.year,
          priceFils: 24999,
          status: ProSubscriptionStatus.active,
          currentPeriodEnd: DateTime(2027, 9, 24, 12),
        ),
      );
    await pump(tester);

    await tester.tap(find.text('Join for KD 24.999 / year'));
    await settle(tester);
    await tester.tap(find.text('Subscribe'));
    await settle(tester);

    expect(membership.state.isMember, isTrue);
    expect(find.text('Welcome to Hero Pro!'), findsOneWidget);
    // Behind the sheet the page is a member's now: the card, no CTA.
    expect(find.text('Your member card for every order'), findsOneWidget);
    expect(find.byType(ProJoinButton), findsNothing);

    await tester.tap(find.text('Start shopping'));
    await settle(tester);

    expect(find.text('Welcome to Hero Pro!'), findsNothing);
    expect(tester.takeException(), isNull);

    await teardownApp(tester);
  });

  testWidgets('member, Arabic, 360×640, text × 1.3: the card lays out', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository.subscription = Right(
      ProSubscription(
        id: 'sub1',
        planId: 'annual',
        planName: 'سنوي',
        interval: ProBillingInterval.year,
        priceFils: 24999,
        status: ProSubscriptionStatus.cancelled,
        cancelAtPeriodEnd: true,
        currentPeriodEnd: DateTime(2027, 9, 24, 12),
      ),
    );
    await pump(
      tester,
      reducedMotion: true,
      locale: const Locale('ar'),
      logicalSize: const Size(360, 640),
      textScale: 1.3,
    );

    await tester.dragUntilVisible(
      find.text('بطاقتك كعضو على كل طلب'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('بطاقتك كعضو على كل طلب'), findsOneWidget);
    // Cancelled while the period runs: benefits until the date, no cancel.
    expect(find.text('إلغاء التجديد'), findsNothing);
    expect(tester.takeException(), isNull);

    await teardownApp(tester);
  });

  testWidgets('programme switched off → unavailable', (tester) async {
    repository.program = const Right(ProProgram(plans: []));
    await pump(tester);

    expect(find.text('Hero Pro is not available right now'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('guest: sign in to join comes back to this page', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Sign in to join'));
    await settle(tester);

    expect(find.text('route:login'), findsOneWidget);
    expect(loginExtra, isA<LoginArgs>());
    final args = loginExtra! as LoginArgs;
    expect(args.returnTo, Routes.proMembership);
    expect(args.sessionExpired, isFalse);

    await teardownApp(tester);
  });

  testWidgets('member: the member hero and their perks, on; no plan tabs', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository.subscription = Right(
      ProSubscription(
        id: 'sub1',
        planId: 'monthly',
        planName: 'Monthly',
        priceFils: 2999,
        status: ProSubscriptionStatus.active,
        currentPeriodEnd: DateTime(2026, 10, 17, 12),
      ),
    );
    await pump(tester);

    expect(find.text("You're Pro"), findsOneWidget);
    expect(find.text('Perks are on'), findsOneWidget);
    expect(find.text('Annual'), findsNothing);
    expect(find.text('Save 31%'), findsNothing);
    expect(find.text('Your perks'), findsOneWidget);
    // Points boost, discount, member prices: all three already on.
    expect(find.text('On'), findsNWidgets(3));

    await teardownApp(tester);
  });

  testWidgets('cancelled member: still Pro until the date, no renewal', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository.subscription = Right(
      ProSubscription(
        id: 'sub1',
        planId: 'monthly',
        planName: 'Monthly',
        status: ProSubscriptionStatus.cancelled,
        cancelAtPeriodEnd: true,
        currentPeriodEnd: DateTime(2026, 10, 17, 12),
      ),
    );
    await pump(tester);

    expect(find.text('Still Pro'), findsOneWidget);
    expect(find.text('until Oct 17'), findsOneWidget);
    expect(find.text('Benefits until Sat, Oct 17, 2026'), findsOneWidget);
    expect(
      find.text(
        "Your membership won't renew. Your perks stay on until "
        'Sat, Oct 17, 2026.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel renewal'), findsNothing);
    expect(find.byType(ProJoinButton), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('lapsed member: welcomed back, told when it ended, rejoin', (
    tester,
  ) async {
    session.signedIn(_customer);
    repository.subscription = Right(
      ProSubscription(
        id: 'sub1',
        planId: 'monthly',
        planName: 'Monthly',
        status: ProSubscriptionStatus.expired,
        currentPeriodEnd: DateTime(2026, 9, 17, 12),
      ),
    );
    await pump(tester);

    expect(find.text('Welcome back, Ahmed'), findsOneWidget);
    expect(
      find.text('Your membership ended on Thu, Sep 17, 2026.'),
      findsOneWidget,
    );
    // The plans are on sale again, best value first.
    expect(find.text('Annual'), findsOneWidget);
    expect(find.text('Rejoin for KD 24.999 / year'), findsOneWidget);
    expect(find.text('On'), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('the page reports what it learned to the app-global status', (
    tester,
  ) async {
    session.signedIn(_customer);
    final status = buildProStatus();
    await status.start(_customer);
    expect(status.state.membership.standing, ProStanding.prospect);
    repository.subscription = Right(
      ProSubscription(
        id: 'sub1',
        planId: 'monthly',
        status: ProSubscriptionStatus.active,
        cancelAtPeriodEnd: true,
        currentPeriodEnd: DateTime(2026, 10, 17, 12),
      ),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProMembershipCubit>.value(value: membership),
          BlocProvider<ProStatusCubit>.value(value: status),
        ],
        child: const ProStatusReporter(child: SizedBox()),
      ),
    );

    await membership.load();
    await tester.pump();

    expect(status.state.membership.standing, ProStanding.ending);
    expect(status.state.isConfirmed, isTrue);
    // Also drops the watch on the period's end (a pending timer).
    await status.close();
  });

  testWidgets('a saved membership is never reported; the server answer is', (
    tester,
  ) async {
    session.signedIn(_customer);
    final status = buildProStatus();
    await status.start(_customer);
    final renewing = ProSubscription(
      id: 'sub1',
      planId: 'monthly',
      status: ProSubscriptionStatus.active,
      currentPeriodEnd: DateTime(2026, 10, 17, 12),
    );
    repository
      ..savedSubscription = renewing
      ..subscription = const Left(NetworkFailure());
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProMembershipCubit>.value(value: membership),
          BlocProvider<ProStatusCubit>.value(value: status),
        ],
        child: const ProStatusReporter(child: SizedBox()),
      ),
    );

    await membership.load();
    await tester.pump();

    expect(membership.state.isMember, isTrue, reason: 'the saved copy shows');
    expect(status.state.membership.standing, ProStanding.prospect);

    repository.subscription = Right(renewing);
    await membership.refresh();
    await tester.pump();

    expect(status.state.membership.standing, ProStanding.active);
    expect(status.state.isConfirmed, isTrue);
    await status.close();
  });
}
