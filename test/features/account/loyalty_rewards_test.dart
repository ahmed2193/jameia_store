// Rewards screen: the redemption tiers derived from the loyalty programme,
// the use case that reads the programme + balance together, the page cubit
// (stale replies dropped) and the page body (sections, locked cards,
// signed-out view, redeeming into the basket).
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_loyalty_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/motion/confetti_burst.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/account/domain/entities/ledger.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_entry_entity.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_program.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_reward.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_rewards.dart';
import 'package:jameia_mart/src/features/account/domain/repositories/loyalty_repository.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/get_loyalty_rewards_usecase.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/loyalty_rewards_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/loyalty_rewards_state.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/loyalty_rewards_page.dart';
import 'package:jameia_mart/src/features/account/presentation/widgets/rewards/reward_card.dart';
import 'package:jameia_mart/src/features/account/presentation/widgets/rewards/reward_off_pill.dart';
import 'package:jameia_mart/src/features/account/presentation/widgets/rewards/rewards_balance_card.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/add_cart_items_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/adjust_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/fetch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/flush_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/reset_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/restore_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_express_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_line_quantity_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/sync_cart_owner_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/watch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';

/// The live programme: 1 point = 1 fils, redeem from 100 points.
const LoyaltyProgram _liveProgram = LoyaltyProgram(
  enabled: true,
  pointsPerKwd: 10,
  redemptionPerPoint: 1,
  minRedeemPoints: 100,
);

Ledger<LoyaltyEntryEntity> _ledgerWith(int balance) =>
    Ledger<LoyaltyEntryEntity>(
      balance: balance,
      entries: const [],
      page: 1,
      hasMore: false,
    );

class _FakeLoyaltyRepository implements LoyaltyRepository {
  _FakeLoyaltyRepository({required this.program, required this.ledger});

  Either<Failure, LoyaltyProgram> program;
  Either<Failure, Ledger<LoyaltyEntryEntity>> ledger;
  final List<(int, int)> ledgerCalls = [];

  @override
  Future<Either<Failure, LoyaltyProgram>> getProgram() async => program;

  @override
  Future<Either<Failure, Ledger<LoyaltyEntryEntity>>> getLedger({
    required int page,
    required int limit,
  }) async {
    ledgerCalls.add((page, limit));
    return ledger;
  }
}

/// Answers through [handler] (hold a reply on a completer to build a race).
class _FakeGetLoyaltyRewardsUseCase implements GetLoyaltyRewardsUseCase {
  _FakeGetLoyaltyRewardsUseCase(this.handler);

  Future<Either<Failure, LoyaltyRewards>> Function() handler;
  int calls = 0;

  @override
  Future<Either<Failure, LoyaltyRewards>> call(NoParams params) {
    calls++;
    return handler();
  }
}

CartCubit _cartCubitOver(FakeCartRepository repository) => CartCubit(
  watch: WatchCartUseCase(repository),
  restore: RestoreCartUseCase(repository),
  syncOwner: SyncCartOwnerUseCase(repository),
  fetch: FetchCartUseCase(repository),
  flush: FlushCartUseCase(repository),
  adjustLine: AdjustCartLineUseCase(repository),
  setLineQuantity: SetCartLineQuantityUseCase(repository),
  removeLine: RemoveCartLineUseCase(repository),
  addItems: AddCartItemsUseCase(repository),
  clear: ClearCartUseCase(repository),
  applyCoupon: ApplyCartCouponUseCase(repository),
  removeCoupon: RemoveCartCouponUseCase(repository),
  applyLoyalty: ApplyCartLoyaltyUseCase(repository),
  removeLoyalty: RemoveCartLoyaltyUseCase(repository),
  setExpress: SetCartExpressUseCase(repository),
  reset: ResetCartUseCase(repository),
);

const CartSnapshot _basket = CartSnapshot(
  cart: CartEntity(
    itemCount: 1,
    lines: <CartLineEntity>[
      CartLineEntity(
        key: 'l1',
        product: testProduct,
        quantity: 1,
        unitPriceFils: 1500,
        lineTotalFils: 1500,
      ),
    ],
  ),
  isRestored: true,
);

/// [_basket] after the server took [points] off it (`GET /v1/cart` →
/// `loyalty`).
CartSnapshot _basketWithPoints(int points) => CartSnapshot(
  cart: CartEntity(
    itemCount: 1,
    lines: _basket.cart.lines,
    loyalty: CartLoyaltyEntity(pointsApplied: points, discountFils: points),
  ),
  isRestored: true,
  revision: 1,
);

void main() {
  group('LoyaltyRewards.from', () {
    test('the live programme → 100 / 200 / 500 / 1000 points', () {
      final rewards = LoyaltyRewards.from(_liveProgram, 0);

      expect(rewards.isAvailable, isTrue);
      expect(rewards.rewards.map((reward) => reward.points), [
        100,
        200,
        500,
        1000,
      ]);
      expect(rewards.rewards.map((reward) => reward.valueFils), [
        100,
        200,
        500,
        1000,
      ]);
      expect(rewards.rewards.map((reward) => reward.valueKd), [
        0.1,
        0.2,
        0.5,
        1.0,
      ]);
    });

    test('no redemption minimum → the fallback step', () {
      final rewards = LoyaltyRewards.from(
        const LoyaltyProgram(enabled: true, redemptionPerPoint: 5),
        0,
      );

      expect(rewards.rewards.first.points, LoyaltyRewards.fallbackStep);
      expect(rewards.rewards.map((reward) => reward.points), [
        100,
        200,
        500,
        1000,
      ]);
      expect(rewards.rewards.map((reward) => reward.valueFils), [
        500,
        1000,
        2500,
        5000,
      ]);
    });

    test('a disabled programme or a worthless point → unavailable', () {
      final disabled = LoyaltyRewards.from(
        const LoyaltyProgram(redemptionPerPoint: 1, minRedeemPoints: 100),
        500,
      );
      final worthless = LoyaltyRewards.from(
        const LoyaltyProgram(enabled: true, minRedeemPoints: 100),
        500,
      );

      expect(disabled.isAvailable, isFalse);
      expect(disabled.rewards, isEmpty);
      expect(worthless.isAvailable, isFalse);
      expect(worthless.rewards, isEmpty);
    });

    test('320 points: two tiers ready, two locked with what is missing', () {
      final rewards = LoyaltyRewards.from(_liveProgram, 320);

      expect(rewards.ready.map((reward) => reward.points), [100, 200]);
      expect(rewards.locked.map((reward) => reward.points), [500, 1000]);
      expect(rewards.missingFor(rewards.locked.first), 180);
      expect(rewards.missingFor(rewards.locked.last), 680);
      expect(rewards.missingFor(rewards.ready.first), 0);
      expect(rewards.balanceValueKd, closeTo(0.32, 1e-9));
    });

    test('a balance exactly on a tier makes it ready', () {
      final rewards = LoyaltyRewards.from(_liveProgram, 500);

      expect(rewards.ready.map((reward) => reward.points), [100, 200, 500]);
      expect(
        rewards.missingFor(const LoyaltyReward(points: 500, valueFils: 500)),
        0,
      );
    });
  });

  group('GetLoyaltyRewardsUseCase', () {
    test('programme + balance → the tiers; asks for one ledger line', () async {
      final repository = _FakeLoyaltyRepository(
        program: const Right(_liveProgram),
        ledger: Right(_ledgerWith(320)),
      );

      final result = await GetLoyaltyRewardsUseCase(repository)(
        const NoParams(),
      );

      expect(result, Right(LoyaltyRewards.from(_liveProgram, 320)));
      expect(repository.ledgerCalls, [(1, 1)]);
    });

    test('a guest: the ledger 401 comes through as-is', () async {
      final repository = _FakeLoyaltyRepository(
        program: const Right(_liveProgram),
        ledger: const Left(UnauthorizedFailure()),
      );

      final result = await GetLoyaltyRewardsUseCase(repository)(
        const NoParams(),
      );

      expect(result, const Left(UnauthorizedFailure()));
    });

    test('the programme fails → that failure', () async {
      final repository = _FakeLoyaltyRepository(
        program: const Left(NetworkFailure()),
        ledger: Right(_ledgerWith(320)),
      );

      final result = await GetLoyaltyRewardsUseCase(repository)(
        const NoParams(),
      );

      expect(result, const Left(NetworkFailure()));
    });
  });

  group('LoyaltyRewardsCubit', () {
    final loaded = LoyaltyRewards.from(_liveProgram, 320);

    test('load: loading → loaded', () async {
      final cubit = LoyaltyRewardsCubit(
        _FakeGetLoyaltyRewardsUseCase(() async => Right(loaded)),
      );
      final states = <LoyaltyRewardsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.map((state) => state.status), [
        LoyaltyRewardsStatus.loading,
        LoyaltyRewardsStatus.loaded,
      ]);
      expect(cubit.state.rewards, loaded);
      await subscription.cancel();
      await cubit.close();
    });

    test(
      'load fails → error with the failure; 401 is the signed-out view',
      () async {
        final useCase = _FakeGetLoyaltyRewardsUseCase(
          () async => const Left(NetworkFailure()),
        );
        final cubit = LoyaltyRewardsCubit(useCase);

        await cubit.load();
        expect(cubit.state.status, LoyaltyRewardsStatus.error);
        expect(cubit.state.failure, const NetworkFailure());
        expect(cubit.state.isSignedOut, isFalse);

        useCase.handler = () async => const Left(UnauthorizedFailure());
        await cubit.load();
        expect(cubit.state.status, LoyaltyRewardsStatus.error);
        expect(cubit.state.isSignedOut, isTrue);
        await cubit.close();
      },
    );

    test('a failed refresh keeps the tiers on screen', () async {
      final useCase = _FakeGetLoyaltyRewardsUseCase(() async => Right(loaded));
      final cubit = LoyaltyRewardsCubit(useCase);
      await cubit.load();

      useCase.handler = () async => const Left(NetworkFailure());
      await cubit.refresh();

      expect(cubit.state.status, LoyaltyRewardsStatus.loaded);
      expect(cubit.state.rewards, loaded);
      expect(cubit.state.failure, const NetworkFailure());
      await cubit.close();
    });

    test('the same refresh failure twice is reported twice', () async {
      final useCase = _FakeGetLoyaltyRewardsUseCase(() async => Right(loaded));
      final cubit = LoyaltyRewardsCubit(useCase);
      await cubit.load();
      final states = <LoyaltyRewardsState>[];
      final subscription = cubit.stream.listen(states.add);

      useCase.handler = () async => const Left(NetworkFailure());
      await cubit.refresh();
      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(states.map((state) => (state.status, state.failure)), [
        (LoyaltyRewardsStatus.loaded, const NetworkFailure()),
        (LoyaltyRewardsStatus.loaded, null),
        (LoyaltyRewardsStatus.loaded, const NetworkFailure()),
      ]);
      expect(states.every((state) => state.rewards == loaded), isTrue);
      await subscription.cancel();
      await cubit.close();
    });

    test('a failed first load keeps its failure while retrying', () async {
      final useCase = _FakeGetLoyaltyRewardsUseCase(
        () async => const Left(UnauthorizedFailure()),
      );
      final cubit = LoyaltyRewardsCubit(useCase);
      await cubit.load();
      final states = <LoyaltyRewardsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      // Error → error with an equal failure: nothing emitted, and the
      // sign-in view never loses its failure in between.
      expect(states, isEmpty);
      expect(cubit.state.isSignedOut, isTrue);
      await subscription.cancel();
      await cubit.close();
    });

    test('a stale reply that lands after a newer one is dropped', () async {
      final stale = Completer<Either<Failure, LoyaltyRewards>>();
      final fresh = Completer<Either<Failure, LoyaltyRewards>>();
      final replies = [stale, fresh];
      final cubit = LoyaltyRewardsCubit(
        _FakeGetLoyaltyRewardsUseCase(() => replies.removeAt(0).future),
      );

      final first = cubit.load();
      final second = cubit.refresh();
      fresh.complete(Right(loaded));
      await second;
      stale.complete(Right(LoyaltyRewards.from(_liveProgram, 5)));
      await first;

      expect(cubit.state.status, LoyaltyRewardsStatus.loaded);
      expect(cubit.state.rewards.balance, 320);
      await cubit.close();
    });
  });

  group('LoyaltyRewardsPage', () {
    late _FakeGetLoyaltyRewardsUseCase useCase;
    late FakeCartRepository cartRepository;
    late CartCubit cartCubit;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() {
      useCase = _FakeGetLoyaltyRewardsUseCase(
        () async => Right(LoyaltyRewards.from(_liveProgram, 320)),
      );
      if (sl.isRegistered<LoyaltyRewardsCubit>()) {
        sl.unregister<LoyaltyRewardsCubit>();
      }
      sl.registerFactory<LoyaltyRewardsCubit>(
        () => LoyaltyRewardsCubit(useCase),
      );
      cartRepository = FakeCartRepository();
      cartCubit = _cartCubitOver(cartRepository);
    });

    tearDown(() async {
      await cartCubit.close();
      await cartRepository.dispose();
    });

    /// The page on a tall phone (every card built and on screen) by default;
    /// [physicalSize] (at 2x), [locale] and [textScale] pick another device.
    /// With [reducedMotion] (the default) every animation is instant and
    /// nothing loops, so the tree settles; without it the caller pumps fixed
    /// durations (the glow and the floating gifts never settle).
    Future<void> pump(
      WidgetTester tester, {
      bool reducedMotion = true,
      Size physicalSize = const Size(1080, 2400),
      Locale locale = const Locale('en'),
      double? textScale,
    }) async {
      tester.view.physicalSize = physicalSize;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      if (textScale != null) {
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      if (reducedMotion) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      }
      await tester.runAsync(() async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: locale,
            saveLocale: false,
            child: BlocProvider<CartCubit>.value(
              value: cartCubit,
              child: Builder(
                builder: (context) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: const LoyaltyRewardsPage(),
                ),
              ),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
      });
      // Another locale's Material delegates take a few real turns to load;
      // the page is built once they have.
      for (
        var turn = 0;
        turn < 20 && find.byType(LoyaltyRewardsPage).evaluate().isEmpty;
        turn++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      if (reducedMotion) {
        await tester.pumpAndSettle();
      } else {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    /// The server's cart snapshot, delivered in the zone the cart listens in.
    Future<void> pushCart(WidgetTester tester, CartSnapshot snapshot) async {
      await tester.runAsync(() async {
        cartRepository.push(snapshot);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
    }

    /// A cart with one line. The cubit subscribes in the real zone: a
    /// subscription opened in the test's fake zone could not be cancelled
    /// by the tear-down once that zone stops being pumped.
    Future<void> startCartWithBasket(WidgetTester tester) async {
      cartRepository.snapshot = _basket;
      await tester.runAsync(() async {
        cartCubit.start();
        await Future<void>.delayed(Duration.zero);
      });
      expect(cartCubit.state.isEmpty, isFalse);
    }

    testWidgets('320 points: ready and locked sections with their cards', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Your points'), findsOneWidget);
      expect(find.text('320 pts'), findsOneWidget);
      expect(find.text('Worth KD 0.320'), findsOneWidget);
      expect(find.text('Points history'), findsOneWidget);
      expect(find.text('Ready to redeem'), findsOneWidget);
      expect(find.text('Keep earning'), findsOneWidget);
      expect(find.text('KD 0.100 off'), findsOneWidget);
      expect(find.text('KD 0.100 off your basket'), findsOneWidget);
      expect(find.text('100 points'), findsOneWidget);
      expect(find.text('200 points'), findsOneWidget);
      expect(find.text('180 more points'), findsOneWidget);
      expect(find.text('680 more points'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
    });

    testWidgets('the balance card shows the way to the next locked tier', (
      tester,
    ) async {
      await pump(tester);

      expect(
        find.text('180 more points to unlock KD 0.500 off'),
        findsOneWidget,
      );
    });

    testWidgets('nothing locked → no next-tier caption', (tester) async {
      useCase.handler = () async =>
          Right(LoyaltyRewards.from(_liveProgram, 1000));
      await pump(tester);

      expect(find.text('1000 pts'), findsOneWidget);
      expect(find.textContaining('to unlock'), findsNothing);
      expect(find.text('Keep earning'), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('the tier the cart carries shows the Applied chip', (
      tester,
    ) async {
      await startCartWithBasket(tester);
      await pump(tester);
      expect(find.text('Applied'), findsNothing);

      await pushCart(tester, _basketWithPoints(200));

      expect(find.text('Applied'), findsOneWidget);
      final appliedCard = find.ancestor(
        of: find.text('Applied'),
        matching: find.byType(RewardCard),
      );
      expect(
        find.descendant(of: appliedCard, matching: find.text('200 points')),
        findsOneWidget,
      );

      await pushCart(tester, _basket);
      expect(find.text('Applied'), findsNothing);
    });

    testWidgets('with motion: the balance counts up, a redeem bursts once', (
      tester,
    ) async {
      await startCartWithBasket(tester);
      await pump(tester, reducedMotion: false);

      expect(find.text('320 pts'), findsOneWidget);
      expect(
        find.text('180 more points to unlock KD 0.500 off'),
        findsOneWidget,
      );
      expect(
        tester.widget<ConfettiBurst>(find.byType(ConfettiBurst)).playKey,
        isNull,
      );

      await tester.tap(find.text('KD 0.200 off your basket'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(cartRepository.calls, contains('applyLoyalty:200'));
      expect(find.text('200 points applied to your basket'), findsOneWidget);
      expect(
        tester.widget<ConfettiBurst>(find.byType(ConfettiBurst)).playKey,
        1,
      );

      // Loops never settle: unmount, then let the one-shot timers run out.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the applied tier: a tap neither re-sends nor re-celebrates', (
      tester,
    ) async {
      await startCartWithBasket(tester);
      await pump(tester);
      await pushCart(tester, _basketWithPoints(200));
      expect(find.text('Applied'), findsOneWidget);

      await tester.tap(find.text('KD 0.200 off your basket'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(cartRepository.calls, isNot(contains('applyLoyalty:200')));
      expect(find.byType(SnackBar), findsNothing);
      expect(
        tester.widget<ConfettiBurst>(find.byType(ConfettiBurst)).playKey,
        isNull,
      );
    });

    testWidgets('Arabic, 360 wide, text x1.3: the off pills show the whole '
        'amount', (tester) async {
      await pump(
        tester,
        physicalSize: const Size(720, 1280),
        locale: const Locale('ar'),
        textScale: 1.3,
      );

      final pills = find.descendant(
        of: find.byType(RewardOffPill),
        matching: find.byType(Text),
      );
      // The balance fills the short screen: scroll the cards in a stretch
      // at a time and check every pill that is built.
      final checked = <String>{};
      for (var stretch = 0; stretch < 6; stretch++) {
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          pills,
        )) {
          final label = paragraph.text.toPlainText();
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          checked.add(label);
        }
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      expect(checked, hasLength(4)); // one pill per tier, all seen
      expect(tester.takeException(), isNull);
    });

    testWidgets('text on the warm balance card and the off pills is legible', (
      tester,
    ) async {
      await pump(tester);

      Finder textIn(Type type) =>
          find.descendant(of: find.byType(type), matching: find.byType(Text));
      await expectLater(
        tester,
        meetsGuideline(
          CustomMinimumContrastGuideline(finder: textIn(RewardsBalanceCard)),
        ),
      );
      await expectLater(
        tester,
        meetsGuideline(
          CustomMinimumContrastGuideline(finder: textIn(RewardOffPill)),
        ),
      );
    });

    testWidgets('the section titles are headings', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(
        tester.getSemantics(find.text('Ready to redeem')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSemantics(find.text('Keep earning')),
        isSemantics(isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('a guest → the sign-in prompt', (tester) async {
      useCase.handler = () async => const Left(UnauthorizedFailure());
      await pump(tester);

      expect(find.text('Sign in to see your points'), findsOneWidget);
      expect(find.text('Ready to redeem'), findsNothing);
    });

    testWidgets('no programme → not available', (tester) async {
      useCase.handler = () async =>
          Right(LoyaltyRewards.from(LoyaltyProgram.none, 320));
      await pump(tester);

      expect(find.text('Rewards are not available right now'), findsOneWidget);
    });

    testWidgets('an empty basket: tapping a ready card asks for items first', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('KD 0.100 off your basket'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Add items to your basket first, then redeem your points.'),
        findsOneWidget,
      );
      expect(cartRepository.calls, isNot(contains('applyLoyalty:100')));
    });

    testWidgets('with a basket: a ready card spends its points', (
      tester,
    ) async {
      await startCartWithBasket(tester);
      await pump(tester);

      await tester.tap(find.text('KD 0.200 off your basket'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(cartRepository.calls, contains('applyLoyalty:200'));
      expect(find.text('200 points applied to your basket'), findsOneWidget);
    });

    testWidgets('a locked card is not tappable', (tester) async {
      await startCartWithBasket(tester);
      await pump(tester);

      await tester.tap(find.text('180 more points'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(cartRepository.calls, isNot(contains('applyLoyalty:500')));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the server refuses → its message', (tester) async {
      await startCartWithBasket(tester);
      await pump(tester);
      // Scripted after start: the restore it runs would consume it.
      cartRepository.failure = const ServerFailure(
        'Not enough points',
        statusCode: 400,
        code: 'LOYALTY_INSUFFICIENT',
      );

      await tester.tap(find.text('KD 0.100 off your basket'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Not enough points'), findsOneWidget);
    });
  });
}
