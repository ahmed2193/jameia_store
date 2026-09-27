// The "Coupons & offers" page (Routes.checkoutVouchers): the code row and
// its sheet (length rule before any call, the coupon's own refusal only, a
// busy cart's "try again", success only once the sent code is on the cart,
// then back to checkout), the applied coupon ticket, the offer tickets from
// the cart enriched by the store's list (applied / locked, "to qualify" for
// a non-stackable one, other branches left out, never an "Apply" or a "Best
// offer"), the expiry (date or countdown), the first-screenful cascade and
// the page's one clock that rests while it is covered.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_applied_offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/motion/second_clock_scope.dart';
import 'package:jameia_mart/src/core/widgets/countdown_digits.dart';
import 'package:jameia_mart/src/core/widgets/jameia_submit_button.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_store_offers_usecase.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_offers_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/pages/checkout_vouchers_page.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_sheet_frame.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/vouchers/checkout_code_field.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/vouchers/checkout_coupon_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/vouchers/checkout_offer_ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  late FakeCheckoutCatalogRepository catalog;
  CartCubit? cart;
  var revision = 0;

  const home = 'checkout';

  const totals = CartTotalsEntity(
    subtotalFils: 2100,
    deliveryFeeFils: 500,
    totalFils: 2600,
  );

  const percentOffer = OfferEntity(
    id: 'pct',
    name: 'Big basket',
    rewardType: OfferRewardType.percentageDiscount,
    percent: 10,
    maxDiscountFils: 3000,
    minSubtotalFils: 5000,
    stackable: true,
  );
  const soloOffer = OfferEntity(
    id: 'solo',
    name: 'On its own',
    rewardType: OfferRewardType.fixedDiscount,
    amountFils: 2000,
  );

  CartOfferProgressEntity locked(
    String offerId, {
    int remaining = 1500,
    OfferProgressKind kind = OfferProgressKind.subtotal,
    String? contextName,
    OfferRewardType reward = OfferRewardType.percentageDiscount,
  }) => CartOfferProgressEntity(
    offerId: offerId,
    name: 'Offer $offerId',
    kind: kind,
    currentValue: 2100,
    targetValue: 2100 + remaining,
    remainingValue: remaining,
    contextName: contextName,
    reward: OfferRewardEntity(type: reward, percent: 10, amountFils: 1000),
  );

  CartEntity cartWith({
    CartCouponEntity? coupon,
    List<CartAppliedOfferEntity> applied = const <CartAppliedOfferEntity>[],
    List<CartOfferProgressEntity> progress = const <CartOfferProgressEntity>[],
  }) => CartEntity(
    itemCount: 1,
    lines: const <CartLineEntity>[
      CartLineEntity(
        key: 'l1',
        product: testProduct,
        quantity: 1,
        unitPriceFils: 2100,
        lineTotalFils: 2100,
      ),
    ],
    totals: totals,
    coupon: coupon,
    appliedOffers: applied,
    offerProgress: progress,
  );

  CartSnapshot snapshotOf(CartEntity cart, {Failure? failure}) => CartSnapshot(
    cart: cart,
    isRestored: true,
    failure: failure,
    failedAction: failure == null ? CartAction.none : CartAction.sync,
    revision: ++revision,
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  setUp(() {
    cartRepository = FakeCartRepository()..snapshot = snapshotOf(cartWith());
    cart = null;
    catalog = FakeCheckoutCatalogRepository();
    if (sl.isRegistered<CheckoutOffersCubit>()) {
      sl.unregister<CheckoutOffersCubit>();
    }
    sl.registerFactory<CheckoutOffersCubit>(
      () => CheckoutOffersCubit(GetStoreOffersUseCase(catalog)),
    );
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    sl.unregister<CheckoutOffersCubit>();
    await cart?.close();
    await cartRepository.dispose();
  });

  /// Checkout (a stub) with the vouchers page pushed over it, the way the
  /// savings row opens it. Returns the router.
  Future<GoRouter> pump(
    WidgetTester tester, {
    String? branchId,
    Size size = const Size(480, 2400),
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      cart = buildCartCubit(cartRepository);
      await Future<void>.delayed(Duration.zero);
    });
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Center(child: Text(home))),
        ),
        GoRoute(
          path: Routes.checkoutVouchers,
          builder: (_, state) {
            final extra = state.extra;
            return CheckoutVouchersPage(
              branchId: extra is String ? extra : null,
            );
          },
        ),
        GoRoute(
          path: '/cover',
          builder: (_, _) => const Scaffold(body: SizedBox.expand()),
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
          child: BlocProvider<CartCubit>.value(
            value: cart!,
            child: Builder(
              builder: (context) => MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    unawaited(router.push(Routes.checkoutVouchers, extra: branchId));
    await tester.pumpAndSettle();
    return router;
  }

  /// Pushes [next] the way the repository stream delivers it.
  Future<void> emit(WidgetTester tester, CartEntity next) async {
    await tester.runAsync(() async {
      cartRepository.push(snapshotOf(next));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  /// Records the haptic kinds the page fires.
  List<Object?> recordHaptics(WidgetTester tester) {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return haptics;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Enter coupon code'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutCouponSheet), findsOneWidget);
  }

  Finder applyButton() => find.descendant(
    of: find.byType(CheckoutCouponSheet),
    matching: find.byType(JameiaSubmitButton),
  );

  /// The entrance cascade's own fade (the only one that keeps semantics).
  final cascadeFade = find.byWidgetPredicate(
    (widget) => widget is FadeTransition && widget.alwaysIncludeSemantics,
  );

  group('the code sheet', () {
    testWidgets('a code shorter than 2 is refused before any call', (
      tester,
    ) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'A');
      await tester.pump();
      await tester.tap(applyButton());
      await tester.pumpAndSettle();

      expect(find.text('A code has 2 to 32 characters'), findsOneWidget);
      expect(
        cartRepository.calls.where((c) => c.startsWith('applyCoupon')),
        isEmpty,
      );
    });

    testWidgets('CT-VP3 a refused code: the field shakes, one warning, the '
        "coupon's own message only", (tester) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(),
        failure: const NetworkFailure('stale sync'),
      );
      await pump(tester);
      final haptics = recordHaptics(tester);
      await openSheet(tester);

      cartRepository.failure = const ServerFailure('This code is not valid');
      await tester.enterText(find.byType(TextField), 'BAD1');
      await tester.pump();
      await tester.tap(applyButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(cartRepository.calls, contains('applyCoupon:BAD1'));
      expect(tester.hasRunningAnimations, isTrue); // the shake
      await tester.pumpAndSettle();
      expect(find.text('This code is not valid'), findsOneWidget);
      expect(find.text('stale sync'), findsNothing);
      expect(
        haptics.where((h) => h == 'HapticFeedbackType.heavyImpact'),
        hasLength(1),
      );
      // Still open: the customer can fix the code.
      expect(find.byType(CheckoutCouponSheet), findsOneWidget);

      // Editing the code clears the refusal.
      await tester.enterText(find.byType(TextField), 'BAD12');
      await tester.pumpAndSettle();
      expect(find.text('This code is not valid'), findsNothing);
    });

    testWidgets('a cart busy with something else: "try again", never a '
        'stale failure', (tester) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(),
        failure: const NetworkFailure('stale sync'),
      );
      await pump(tester);
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'SAVE10');
      await tester.pump();

      final gate = Completer<void>();
      cartRepository.gate = gate;
      await tester.runAsync(() async {
        unawaited(cart!.applyLoyalty(100));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      // The button rests; "done" on the keyboard still tries.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't apply the code. Try again."), findsOneWidget);
      expect(find.text('stale sync'), findsNothing);
      expect(cartRepository.calls, isNot(contains('applyCoupon:SAVE10')));
      await tester.runAsync(() async {
        gate.complete();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
    });

    testWidgets('CT-VP4 applied: one success haptic, the sheet closes and '
        'the page goes back to checkout', (tester) async {
      await pump(tester);
      final haptics = recordHaptics(tester);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'save10');
      await tester.pump();
      await tester.tap(applyButton());
      // The button spins until the code shows up on the cart.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(cartRepository.calls, contains('applyCoupon:save10'));

      // The server kept its own spelling of the code.
      await emit(
        tester,
        cartWith(
          coupon: const CartCouponEntity(code: 'SAVE10', discountFils: 500),
        ),
      );

      expect(find.byType(CheckoutCouponSheet), findsNothing);
      expect(find.byType(CheckoutVouchersPage), findsNothing);
      expect(find.text(home), findsOneWidget);
      expect(
        haptics.where((h) => h == 'HapticFeedbackType.mediumImpact'),
        hasLength(1),
      );
    });

    testWidgets('replacing a code succeeds only once the new code is on the '
        'cart', (tester) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(
          coupon: const CartCouponEntity(code: 'OLD', discountFils: 200),
        ),
      );
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'NEW');
      await tester.pump();
      await tester.tap(applyButton());
      // The button spins until the code shows up on the cart.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // The call went through, but the cart still carries the old code.
      expect(cartRepository.calls, contains('applyCoupon:NEW'));
      expect(find.byType(CheckoutCouponSheet), findsOneWidget);

      await emit(
        tester,
        cartWith(
          coupon: const CartCouponEntity(code: 'NEW', discountFils: 400),
        ),
      );
      expect(find.byType(CheckoutCouponSheet), findsNothing);
      expect(find.text(home), findsOneWidget);
    });

    testWidgets('CT-VP6 typing rebuilds only the Apply button', (tester) async {
      await pump(tester);
      await openSheet(tester);
      final probe = RebuildProbe<Widget, Type>((widget) => widget.runtimeType)
        ..start();
      addTearDown(probe.stop);

      await tester.enterText(find.byType(TextField), 'SAVE');
      await tester.pump();

      expect(probe.of(CheckoutSheetFrame), 0);
      expect(probe.of(CheckoutCodeField), 0);
      expect(probe.of(CheckoutCouponSheet), 0);
      expect(probe.of(JameiaSubmitButton), greaterThan(0));
      probe.stop();
    });
  });

  group('the applied coupon', () {
    testWidgets('shows its saving and removes', (tester) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(
          coupon: const CartCouponEntity(code: 'SAVE10', discountFils: 500),
        ),
      );
      await pump(tester);

      expect(find.text('Your coupon'), findsOneWidget);
      expect(find.text('SAVE10'), findsOneWidget);
      expect(find.text('KD 0.500 saved'), findsOneWidget);
      expect(find.text('Applied'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(cartRepository.calls, contains('removeCoupon'));
    });

    testWidgets('a code that saves nothing says so', (tester) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(coupon: const CartCouponEntity(code: 'ZERO')),
      );
      await pump(tester);

      expect(
        find.text('Applied, but it saves nothing on this basket'),
        findsOneWidget,
      );
    });
  });

  group('offers', () {
    testWidgets('CT-VP5 applied offers show Applied; no Apply, no Best '
        'offer', (tester) async {
      catalog.offers = const <OfferEntity>[percentOffer];
      cartRepository.snapshot = snapshotOf(
        cartWith(
          applied: const <CartAppliedOfferEntity>[
            CartAppliedOfferEntity(
              offerId: 'pct',
              name: 'Big basket',
              discountFils: 300,
              reward: OfferRewardEntity(
                type: OfferRewardType.percentageDiscount,
                percent: 10,
                maxDiscountFils: 3000,
              ),
            ),
          ],
        ),
      );
      await pump(tester);

      expect(find.text('Applied to your order'), findsOneWidget);
      expect(find.byType(CheckoutOfferTicket), findsOneWidget);
      expect(find.text('10% off'), findsOneWidget);
      expect(
        find.text('Min. order KD 5.000 · Save up to KD 3.000'),
        findsOneWidget,
      );
      expect(find.text('KD 0.300 saved'), findsOneWidget);
      expect(find.text('Applied'), findsOneWidget);
      expect(find.text('Combines with other offers'), findsOneWidget);
      expect(find.text('Apply'), findsNothing);
      expect(find.textContaining('Best'), findsNothing);
      expect(find.text("That's everything for now"), findsOneWidget);
    });

    testWidgets('a locked offer shows what is missing; a non-stackable one '
        'only qualifies', (tester) async {
      catalog.offers = const <OfferEntity>[percentOffer, soloOffer];
      cartRepository.snapshot = snapshotOf(
        cartWith(
          progress: [
            locked('pct', remaining: 1500),
            locked(
              'solo',
              remaining: 900,
              reward: OfferRewardType.fixedDiscount,
            ),
            locked(
              'dairy',
              remaining: 2,
              kind: OfferProgressKind.category,
              contextName: 'Dairy',
            ),
          ],
        ),
      );
      await pump(tester);

      expect(find.text('Add more to unlock'), findsOneWidget);
      // Headlines come from the reward.
      expect(find.text('10% off'), findsNWidgets(2));
      expect(find.text('KD 1.000 off'), findsOneWidget);
      expect(find.text('Add KD 1.500 more to unlock'), findsOneWidget);
      expect(find.text('Add KD 0.900 more to qualify'), findsOneWidget);
      expect(find.text("Can't be combined"), findsOneWidget);
      // Not in the store's list: built from the cart alone, no ribbon.
      expect(find.text('Add 2 more from Dairy'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
      expect(find.text('Apply'), findsNothing);
    });

    testWidgets('offers limited to other branches are left out', (
      tester,
    ) async {
      catalog.offers = const <OfferEntity>[
        OfferEntity(
          id: 'far',
          name: 'Elsewhere',
          rewardType: OfferRewardType.percentageDiscount,
          percent: 10,
          stackable: true,
          branchIds: <String>['b9'],
        ),
      ];
      cartRepository.snapshot = snapshotOf(cartWith(progress: [locked('far')]));
      await pump(tester, branchId: 'b1');

      expect(find.byType(CheckoutOfferTicket), findsNothing);
      expect(find.text('No offers are running right now'), findsOneWidget);
    });

    testWidgets('the same offer shows at its own branch', (tester) async {
      catalog.offers = const <OfferEntity>[
        OfferEntity(
          id: 'far',
          name: 'Elsewhere',
          rewardType: OfferRewardType.percentageDiscount,
          percent: 10,
          stackable: true,
          branchIds: <String>['b9'],
        ),
      ];
      cartRepository.snapshot = snapshotOf(cartWith(progress: [locked('far')]));
      await pump(tester, branchId: 'b9');

      expect(find.byType(CheckoutOfferTicket), findsOneWidget);
    });

    testWidgets('an end beyond a day is a date; within a day a countdown', (
      tester,
    ) async {
      final now = DateTime.now();
      catalog.offers = <OfferEntity>[
        OfferEntity(
          id: 'later',
          name: 'Later',
          rewardType: OfferRewardType.percentageDiscount,
          percent: 10,
          stackable: true,
          endsAt: now.add(const Duration(days: 3)),
        ),
        OfferEntity(
          id: 'soon',
          name: 'Soon',
          rewardType: OfferRewardType.percentageDiscount,
          percent: 10,
          stackable: true,
          endsAt: now.add(const Duration(hours: 6)),
        ),
      ];
      cartRepository.snapshot = snapshotOf(
        cartWith(progress: [locked('later'), locked('soon')]),
      );
      await pump(tester);

      expect(find.textContaining('Valid until'), findsOneWidget);
      expect(find.text('Ends in'), findsOneWidget);
      expect(find.byType(CountdownDigits), findsOneWidget);
    });
  });

  testWidgets('fits a 360 dp phone at 1.3× text in Arabic', (tester) async {
    catalog.offers = <OfferEntity>[
      percentOffer,
      soloOffer,
      OfferEntity(
        id: 'soon',
        name: 'Soon',
        rewardType: OfferRewardType.fixedDiscount,
        amountFils: 1000,
        stackable: true,
        endsAt: DateTime.now().add(const Duration(hours: 6)),
      ),
    ];
    cartRepository.snapshot = snapshotOf(
      cartWith(
        coupon: const CartCouponEntity(code: 'SAVE10', discountFils: 500),
        applied: const <CartAppliedOfferEntity>[
          CartAppliedOfferEntity(
            offerId: 'pct',
            name: 'Big basket',
            discountFils: 300,
            reward: OfferRewardEntity(
              type: OfferRewardType.percentageDiscount,
              percent: 10,
              maxDiscountFils: 3000,
            ),
          ),
        ],
        progress: [
          locked('solo', reward: OfferRewardType.fixedDiscount),
          locked('soon', reward: OfferRewardType.fixedDiscount),
        ],
      ),
    );
    await pump(
      tester,
      locale: const Locale('ar'),
      size: const Size(360, 800),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('أدخل كود الكوبون'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أدخل كود الكوبون'));
    await tester.pumpAndSettle();
    expect(find.text('كود الكوبون'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('motion', () {
    testWidgets('CT-VP1 the first screenful cascades once; tickets scrolled '
        'in later are static', (tester) async {
      catalog.offers = const <OfferEntity>[];
      cartRepository.snapshot = snapshotOf(
        cartWith(
          progress: [
            for (var i = 0; i < 8; i++) locked('o$i', remaining: 100 * (i + 1)),
          ],
        ),
      );
      await pump(tester, size: const Size(360, 800));

      // The first tickets rose in; the last one is built only on scroll.
      final first = find.ancestor(
        of: find.byType(CheckoutOfferTicket).first,
        matching: find.byWidgetPredicate((w) => w.key == const ValueKey('o0')),
      );
      expect(find.descendant(of: first, matching: cascadeFade), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Offer o7'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final last = find.byWidgetPredicate((w) => w.key == const ValueKey('o7'));
      expect(last, findsOneWidget);
      expect(find.descendant(of: last, matching: cascadeFade), findsNothing);

      // A cart update later plays no cascade again.
      await emit(
        tester,
        cartWith(progress: [for (var i = 0; i < 8; i++) locked('o$i')]),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('CT-VP2 the countdown clock runs only while the page is on '
        'stage', (tester) async {
      catalog.offers = <OfferEntity>[
        OfferEntity(
          id: 'soon',
          name: 'Soon',
          rewardType: OfferRewardType.percentageDiscount,
          percent: 10,
          stackable: true,
          endsAt: DateTime.now().add(const Duration(hours: 6)),
        ),
      ];
      cartRepository.snapshot = snapshotOf(
        cartWith(progress: [locked('soon')]),
      );
      final router = await pump(tester);
      final clock = tester
          .state<SecondClockScopeState>(find.byType(SecondClockScope))
          .clock;
      expect(clock.debugIsRunning, isTrue);

      unawaited(router.push('/cover'));
      await tester.pumpAndSettle();
      expect(clock.debugIsRunning, isFalse);

      router.pop();
      await tester.pumpAndSettle();
      expect(clock.debugIsRunning, isTrue);
    });
  });
}
