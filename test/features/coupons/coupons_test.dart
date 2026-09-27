// Coupons wallet: the entity's locale selectors and label dates, the buckets
// and their savings total, the use case's bucketing (marker and past dates,
// on a fixed clock), the cubit (load, failure, retry), the ticket's fade and
// outline cache, and the three screens over real cubits whose repository is
// faked — My coupons (savings card, tab counts, switching tabs, "Use" and its
// tap target), the history groups, the spent tickets' localized dates and
// faded stub, the checkout picker's result, reduced motion, and an Arabic
// small phone at text × 1.3. The wallet loops a glow and a shimmer while
// motion is on, so motion-on tests advance fixed frames instead of settling.
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/feature_routes/coupons_routes.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/coupon_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/features/coupons/domain/entities/coupon_buckets.dart';
import 'package:hero_mart/src/features/coupons/domain/entities/coupon_dates.dart';
import 'package:hero_mart/src/features/coupons/domain/repositories/coupons_repository.dart';
import 'package:hero_mart/src/features/coupons/domain/usecases/get_coupons_usecase.dart';
import 'package:hero_mart/src/features/coupons/presentation/cubit/coupons_cubit.dart';
import 'package:hero_mart/src/features/coupons/presentation/cubit/coupons_state.dart';
import 'package:hero_mart/src/features/coupons/presentation/widgets/coupon_fade.dart';
import 'package:hero_mart/src/features/coupons/presentation/widgets/coupon_stub.dart';
import 'package:hero_mart/src/features/coupons/presentation/widgets/coupon_ticket_clipper.dart';
import 'package:shared_preferences/shared_preferences.dart';

const CouponEntity _kdOne = CouponEntity(
  id: 'c1',
  title: 'KD 1 off',
  titleAr: 'خصم 1 د.ك',
  subtitle: 'Min spend KD 5',
  subtitleAr: 'بحد أدنى 5 د.ك',
  amount: 1,
  minSpend: 5,
  expiry: '2026-12-31',
  used: false,
);

const CouponEntity _delivery = CouponEntity(
  id: 'c2',
  title: 'Free delivery',
  titleAr: 'توصيل مجاني',
  subtitle: 'Any order',
  amount: 0.5,
  minSpend: 0,
  expiry: '2026-09-30',
  used: false,
);

const CouponEntity _twenty = CouponEntity(
  id: 'c3',
  title: '20% off',
  titleAr: 'خصم 20%',
  subtitle: 'Up to KD 3',
  subtitleAr: 'حتى 3 د.ك',
  amount: 3,
  minSpend: 8,
  expiry: '2026-08-15',
  used: false,
);

const CouponEntity _spent = CouponEntity(
  id: 'c4',
  title: 'KD 2 off',
  titleAr: 'خصم 2 د.ك',
  subtitle: 'Min spend KD 10',
  subtitleAr: 'بحد أدنى 10 د.ك',
  amount: 2,
  minSpend: 10,
  expiry: 'Used 2026-05-01',
  used: true,
);

const CouponEntity _lapsed = CouponEntity(
  id: 'c5',
  title: 'Free dessert',
  titleAr: 'حلوى مجانية',
  subtitle: 'Any order',
  subtitleAr: 'على أي طلب',
  amount: 1,
  minSpend: 0,
  expiry: 'Expired 2026-01-15',
  used: false,
);

const CouponEntity _undated = CouponEntity(
  id: 'c9',
  title: 'Soon',
  subtitle: '',
  amount: 1,
  minSpend: 0,
  expiry: 'Limited time',
  used: false,
);

const List<CouponEntity> _all = [_kdOne, _delivery, _twenty, _spent, _lapsed];

/// A fixed "today" before every fixture's date, so the dated coupons stay
/// available whatever day the suite runs.
DateTime _today() => DateTime(2026, 8, 1);

/// The use case on the fixed clock.
GetCouponsUseCase _useCase(CouponsRepository repository) =>
    GetCouponsUseCase(repository, now: _today);

const Map<String, List<String>> _fonts = {
  'Hero': ['Hero-Regular.otf', 'Hero-Medium.otf', 'Hero-Bold.otf'],
  'NotoSansArabicUI': [
    'NotoSansArabicUI-Regular.ttf',
    'NotoSansArabicUI-Medium.ttf',
    'NotoSansArabicUI-Bold.ttf',
  ],
};

class _FakeRepository implements CouponsRepository {
  Either<Failure, List<CouponEntity>> result = const Right(_all);
  int calls = 0;

  @override
  Future<Either<Failure, List<CouponEntity>>> getCoupons() async {
    calls++;
    return result;
  }
}

void main() {
  group('CouponEntity', () {
    test('titleFor / subtitleFor pick Arabic for ar, English otherwise', () {
      expect(_kdOne.titleFor('en'), 'KD 1 off');
      expect(_kdOne.titleFor('ar'), 'خصم 1 د.ك');
      expect(_kdOne.subtitleFor('ar'), 'بحد أدنى 5 د.ك');
      expect(_kdOne.subtitleFor('en'), 'Min spend KD 5');
    });

    test('a blank Arabic value falls back to English', () {
      expect(_delivery.subtitleFor('ar'), 'Any order');
    });

    test('expiryDateLabel / expiryDate pull the ISO date out of the label', () {
      expect(_kdOne.expiryDateLabel, '2026-12-31');
      expect(_spent.expiryDateLabel, '2026-05-01');
      expect(_lapsed.expiryDateLabel, '2026-01-15');
      expect(_lapsed.expiryDate, DateTime(2026, 1, 15));
      expect(_undated.expiryDateLabel, isNull);
      expect(_undated.expiryDate, isNull);
    });
  });

  group('CouponBuckets', () {
    test('savingsUpTo adds up the available amounts only', () {
      const buckets = CouponBuckets(
        available: [_kdOne, _delivery, _twenty],
        used: [_spent],
        expired: [_lapsed],
      );
      expect(buckets.savingsUpTo, closeTo(4.5, 1e-9));
      expect(const CouponBuckets().savingsUpTo, 0);
    });

    test('hasNoHistory', () {
      const buckets = CouponBuckets(available: [_kdOne], used: [_spent]);
      expect(buckets.hasNoHistory, isFalse);
      expect(const CouponBuckets(available: [_kdOne]).hasNoHistory, isTrue);
    });
  });

  group('GetCouponsUseCase', () {
    test('buckets by the used flag, then the expired marker', () async {
      final result = await _useCase(_FakeRepository())(const NoParams());
      final buckets = result.getOrElse(() => const CouponBuckets());
      expect(buckets.available, [_kdOne, _delivery, _twenty]);
      expect(buckets.used, [_spent]);
      expect(buckets.expired, [_lapsed]);
    });

    test(
      'a date before today is expired; the expiry day itself is not',
      () async {
        final repository = _FakeRepository();
        // The day after 20% off's 2026-08-15: it moves to expired.
        final later = await GetCouponsUseCase(
          repository,
          now: () => DateTime(2026, 8, 16, 0, 5),
        )(const NoParams());
        final lapsedBuckets = later.getOrElse(() => const CouponBuckets());
        expect(lapsedBuckets.available, [_kdOne, _delivery]);
        expect(lapsedBuckets.expired, [_twenty, _lapsed]);
        expect(lapsedBuckets.used, [_spent]);
        expect(lapsedBuckets.savingsUpTo, closeTo(1.5, 1e-9));

        // Late on its last day it is still available.
        final lastDay = await GetCouponsUseCase(
          repository,
          now: () => DateTime(2026, 8, 15, 23, 59),
        )(const NoParams());
        expect(lastDay.getOrElse(() => const CouponBuckets()).available, [
          _kdOne,
          _delivery,
          _twenty,
        ]);
      },
    );

    test('a coupon without a date is never expired by the clock', () async {
      final repository = _FakeRepository()..result = const Right([_undated]);
      final result = await GetCouponsUseCase(
        repository,
        now: () => DateTime(2030),
      )(const NoParams());
      expect(result.getOrElse(() => const CouponBuckets()).available, [
        _undated,
      ]);
    });

    test('passes a failure through', () async {
      final repository = _FakeRepository()..result = const Left(CacheFailure());
      final result = await _useCase(repository)(const NoParams());
      expect(result, const Left<Failure, CouponBuckets>(CacheFailure()));
    });
  });

  group('CouponFade', () {
    test('fades to the lifted greyscale, keeping alpha', () {
      // White stays white (0.75 × 255 + 64 clamps to 255).
      expect(
        CouponFade.apply(const Color(0xFFFFFFFF)),
        const Color(0xFFFFFFFF),
      );
      // Black lifts to the 64 offset.
      final black = CouponFade.apply(const Color(0x80000000));
      expect(black.a, closeTo(0x80 / 255, 1e-6));
      expect(black.r, closeTo(64 / 255, 1e-6));
      expect(black.g, closeTo(64 / 255, 1e-6));
      expect(black.b, closeTo(64 / 255, 1e-6));
      // Pure red → 0.16 × 255 + 64 on every channel.
      final red = CouponFade.apply(const Color(0xFFFF0000));
      expect(red.r, closeTo(0.16 + 64 / 255, 1e-6));
      expect(red.g, red.r);
      expect(red.b, red.r);
    });

    test('of / all leave colours alone unless faded', () {
      const orange = Color(0xFFFF8800);
      expect(CouponFade.of(orange, faded: false), orange);
      expect(CouponFade.of(orange, faded: true), CouponFade.apply(orange));
      const colors = [orange, Color(0xFF00FF00)];
      expect(identical(CouponFade.all(colors, faded: false), colors), isTrue);
      expect(
        CouponFade.all(colors, faded: true),
        colors.map(CouponFade.apply).toList(),
      );
    });
  });

  group('CouponTicketClipper.pathFor', () {
    Path outline(Size size, {required bool rtl}) => CouponTicketClipper.pathFor(
      size,
      stubWidth: 96,
      notchRadius: 9,
      cornerRadius: 12,
      rtl: rtl,
    );

    test('the same inputs return the same cached path', () {
      const size = Size(360, 110);
      expect(
        identical(outline(size, rtl: false), outline(size, rtl: false)),
        isTrue,
      );
    });

    test('rtl moves the notches to the other side', () {
      const size = Size(360, 110);
      final ltr = outline(size, rtl: false);
      final rtl = outline(size, rtl: true);
      expect(identical(ltr, rtl), isFalse);
      // Just inside the top edge on each seam: bitten out on its own side.
      const ltrSeam = Offset(96, 2);
      const rtlSeam = Offset(360 - 96, 2);
      expect(ltr.contains(ltrSeam), isFalse);
      expect(ltr.contains(rtlSeam), isTrue);
      expect(rtl.contains(rtlSeam), isFalse);
      expect(rtl.contains(ltrSeam), isTrue);
    });

    test('a new size builds a new path', () {
      final a = outline(const Size(300, 110), rtl: false);
      final b = outline(const Size(300, 120), rtl: false);
      expect(identical(a, b), isFalse);
      expect(b.getBounds().height, 120);
    });
  });

  group('CouponsCubit', () {
    test('does not load on construction', () async {
      final repository = _FakeRepository();
      final cubit = CouponsCubit(_useCase(repository));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, CouponsStatus.initial);
      expect(repository.calls, 0);
      await cubit.close();
    });

    blocTest<CouponsCubit, CouponsState>(
      'load → loading, loaded with the buckets',
      build: () => CouponsCubit(_useCase(_FakeRepository())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const CouponsState(status: CouponsStatus.loading),
        const CouponsState(
          status: CouponsStatus.loaded,
          buckets: CouponBuckets(
            available: [_kdOne, _delivery, _twenty],
            used: [_spent],
            expired: [_lapsed],
          ),
        ),
      ],
    );

    late _FakeRepository failing;
    blocTest<CouponsCubit, CouponsState>(
      'a failure → error with it; retry → loaded, the failure cleared',
      setUp: () =>
          failing = _FakeRepository()..result = const Left(CacheFailure()),
      build: () => CouponsCubit(_useCase(failing)),
      act: (cubit) async {
        await cubit.load();
        failing.result = const Right([_kdOne]);
        await cubit.load();
      },
      expect: () => [
        const CouponsState(status: CouponsStatus.loading),
        const CouponsState(
          status: CouponsStatus.error,
          failure: CacheFailure(),
        ),
        const CouponsState(status: CouponsStatus.loading),
        const CouponsState(
          status: CouponsStatus.loaded,
          buckets: CouponBuckets(available: [_kdOne]),
        ),
      ],
    );
  });

  group('screens', () {
    late _FakeRepository repository;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
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
      repository = _FakeRepository();
      if (sl.isRegistered<CouponsCubit>()) sl.unregister<CouponsCubit>();
      sl.registerFactory<CouponsCubit>(
        () => CouponsCubit(_useCase(repository)),
      );
    });

    /// Plays every entrance / count-up / tab glide to its end. The savings
    /// glow and the "Use" shimmer loop forever while motion is on, so this
    /// advances fixed frames instead of `pumpAndSettle`.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Pumps the coupon routes (plus a stand-in shell) at [location].
    Future<void> pump(
      WidgetTester tester, {
      required String location,
      bool reducedMotion = false,
      Locale locale = const Locale('en'),
      Size logicalSize = const Size(400, 900),
      double textScale = 1,
    }) async {
      Intl.defaultLocale = locale.languageCode;
      addTearDown(() => Intl.defaultLocale = null);
      tester.view.physicalSize = logicalSize * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: location,
        routes: [
          ...couponsRoutes,
          GoRoute(
            path: Routes.shell,
            builder: (_, _) => const Scaffold(body: Text('SHELL')),
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
        );
        // Lets the translation asset load for real.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await settle(tester);
    }

    /// The stub gradient of the ticket titled [title].
    List<Color> stubGradient(WidgetTester tester, String title) {
      final card = find.ancestor(
        of: find.text(title),
        matching: find.byType(RepaintBoundary),
      );
      final stub = find.descendant(
        of: card.first,
        matching: find.byType(CouponStub),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: stub, matching: find.byType(DecoratedBox)).first,
      );
      final gradient = (box.decoration as BoxDecoration).gradient;
      return (gradient! as LinearGradient).colors;
    }

    Future<void> teardownApp(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('My coupons: the savings card and the tab counts', (
      tester,
    ) async {
      await pump(tester, location: Routes.myCoupons);

      expect(find.text('My coupons'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Save up to'), findsOneWidget);
      expect(find.text('KD 4.500'), findsOneWidget);
      expect(find.text('Coupons ready: 3'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
      // The available tickets, each with its "Use" pill.
      expect(find.text('KD 1 off'), findsOneWidget);
      expect(find.text('Free delivery'), findsOneWidget);
      expect(find.text('Use'), findsNWidgets(3));
      expect(stubGradient(tester, 'KD 1 off'), CouponStub.gradient);
      expect(find.text('Valid till \u20682026-12-31\u2069'), findsOneWidget);
      expect(find.text('Min KD 5.000'), findsOneWidget);

      await teardownApp(tester);
    });

    testWidgets('"Use" pills meet the 44 dp tap target', (tester) async {
      await pump(tester, location: Routes.myCoupons);

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      await teardownApp(tester);
    });

    testWidgets('switching to Used shows the stamped used coupon', (
      tester,
    ) async {
      await pump(tester, location: Routes.myCoupons);

      await tester.tap(find.text('Used'));
      await settle(tester);

      expect(find.text('KD 2 off'), findsOneWidget);
      expect(find.text('USED'), findsOneWidget);
      // The localized date chip, the date isolated for bidi.
      expect(find.text('Used \u20682026-05-01\u2069'), findsOneWidget);
      expect(find.text('Use'), findsNothing);
      // Painted in the spent greys, with no offscreen filter layer.
      expect(find.byType(ColorFiltered), findsNothing);
      expect(stubGradient(tester, 'KD 2 off'), CouponStub.fadedGradient);

      await tester.tap(find.text('Expired'));
      await settle(tester);

      expect(find.text('Free dessert'), findsOneWidget);
      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('Expired \u20682026-01-15\u2069'), findsOneWidget);
      expect(stubGradient(tester, 'Free dessert'), CouponStub.fadedGradient);

      await teardownApp(tester);
    });

    testWidgets('"Use" returns to the shell', (tester) async {
      await pump(tester, location: Routes.myCoupons);

      await tester.tap(find.text('Use').first);
      await settle(tester);

      expect(find.text('SHELL'), findsOneWidget);

      await teardownApp(tester);
    });

    testWidgets('tapping a ticket opens its detail sheet', (tester) async {
      await pump(tester, location: Routes.myCoupons);

      await tester.tap(find.text('Free delivery'));
      await settle(tester);

      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('KD 0.500 off'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await settle(tester);

      expect(find.text('Terms'), findsNothing);

      await teardownApp(tester);
    });

    testWidgets('history: the used group, then the expired group', (
      tester,
    ) async {
      await pump(tester, location: Routes.historyCoupons);

      expect(find.text('Coupon history'), findsOneWidget);
      expect(find.text('Used'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('USED'), findsOneWidget);
      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('KD 1 off'), findsNothing);
      final usedTop = tester.getTopLeft(find.text('KD 2 off')).dy;
      final expiredTop = tester.getTopLeft(find.text('Free dessert')).dy;
      expect(usedTop, lessThan(expiredTop));

      await teardownApp(tester);
    });

    testWidgets('history without spent coupons → the empty state', (
      tester,
    ) async {
      repository.result = const Right([_kdOne]);
      await pump(tester, location: Routes.historyCoupons);

      expect(find.text('No coupon history yet'), findsOneWidget);

      await teardownApp(tester);
    });

    testWidgets('first load fails → the error view; retry loads', (
      tester,
    ) async {
      repository.result = const Left(CacheFailure());
      await pump(tester, location: Routes.myCoupons);

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Save up to'), findsNothing);

      repository.result = const Right(_all);
      await tester.tap(find.text('Retry'));
      await settle(tester);

      expect(find.text('Save up to'), findsOneWidget);

      await teardownApp(tester);
    });

    testWidgets('reduced motion: final frames at once, nothing ticking', (
      tester,
    ) async {
      await pump(tester, location: Routes.myCoupons, reducedMotion: true);

      expect(find.text('KD 4.500'), findsOneWidget);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(find.text('Used'));
      await tester.pump();
      await tester.pump();
      expect(find.text('USED'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);

      await teardownApp(tester);
    });

    testWidgets('Arabic small phone at text × 1.3: every screen fits', (
      tester,
    ) async {
      for (final location in [Routes.myCoupons, Routes.historyCoupons]) {
        await pump(
          tester,
          location: location,
          locale: const Locale('ar'),
          logicalSize: const Size(360, 640),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull, reason: location);
        await teardownApp(tester);
      }

      await pump(
        tester,
        location: Routes.myCoupons,
        locale: const Locale('ar'),
        logicalSize: const Size(360, 640),
        textScale: 1.3,
      );
      expect(find.text('كوبوناتي'), findsOneWidget);
      await tester.tap(find.text('مستخدمة'));
      await settle(tester);
      expect(find.text('مُستخدَم'), findsOneWidget);
      // The date chip is Arabic around the isolated date, no English marker.
      expect(find.text('استُخدم في \u20682026-05-01\u2069'), findsOneWidget);
      expect(find.textContaining(RegExp('Used|Expired')), findsNothing);
      await tester.tap(find.text('منتهية'));
      await settle(tester);
      expect(find.text('انتهى في \u20682026-01-15\u2069'), findsOneWidget);
      expect(find.textContaining(RegExp('Used|Expired')), findsNothing);
      expect(tester.takeException(), isNull);

      await teardownApp(tester);
    });
  });
}
