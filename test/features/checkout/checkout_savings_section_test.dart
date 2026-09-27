// "Instant savings" on its own (no receipt, no bar): the coupons-and-offers
// figure from the server's totals, the red unlock tag worded from the
// reward and shown only for an honest unlock, the points row under the
// store's one redeem rule, the way to the vouchers page, and the motion
// contract (a code applied after open pops the tag and counts up once; one
// on the cart at open plays nothing; a change made while covered plays when
// revealed).
import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_loyalty_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/utils/formatters.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_offers_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_red_tag.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_figure.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_section.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_unlock_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  var revision = 0;

  late CheckoutCubit checkoutCubit;
  late AuthSessionCubit session;

  // The cart cubit is built when the section is pumped, over the snapshot
  // the test set up by then, in the real zone (like the repository it
  // listens to); snapshots then reach it through [emit].
  CartCubit? cart;
  CartCubit cartCubit() => cart!;

  /// 2.100 of goods with a 0.500 delivery fee.
  const totals = CartTotalsEntity(
    subtotalFils: 2100,
    deliveryFeeFils: 500,
    baseDeliveryFeeFils: 500,
    totalFils: 2600,
  );
  const lines = <CartLineEntity>[
    CartLineEntity(
      key: 'l1',
      product: testProduct,
      quantity: 2,
      unitPriceFils: 600,
      lineTotalFils: 1200,
    ),
    CartLineEntity(
      key: 'l2',
      product: otherProduct,
      quantity: 1,
      unitPriceFils: 900,
      lineTotalFils: 900,
    ),
  ];

  // The store's offers (`GET /v1/offers`).
  const percentOffer = OfferEntity(
    id: 'pct',
    name: 'Big basket',
    rewardType: OfferRewardType.percentageDiscount,
    percent: 10,
    maxDiscountFils: 3000,
    stackable: true,
  );
  const fixedOffer = OfferEntity(
    id: 'amt',
    name: 'One dinar off',
    rewardType: OfferRewardType.fixedDiscount,
    amountFils: 1000,
    stackable: true,
  );
  const freeOffer = OfferEntity(
    id: 'free',
    name: 'Free delivery over 3 KWD',
    rewardType: OfferRewardType.freeDelivery,
    stackable: true,
  );
  const soloOffer = OfferEntity(
    id: 'solo',
    name: 'Not with others',
    rewardType: OfferRewardType.fixedDiscount,
    amountFils: 2000,
  );
  const elsewhereOffer = OfferEntity(
    id: 'far',
    name: 'Another branch only',
    rewardType: OfferRewardType.fixedDiscount,
    amountFils: 700,
    stackable: true,
    branchIds: <String>['b9'],
  );
  const hereOffer = OfferEntity(
    id: 'near',
    name: 'This branch only',
    rewardType: OfferRewardType.fixedDiscount,
    amountFils: 500,
    stackable: true,
    branchIds: <String>['b1'],
  );

  CartOfferProgressEntity progress(
    String offerId,
    int remaining, {
    OfferRewardType reward = OfferRewardType.fixedDiscount,
  }) => CartOfferProgressEntity(
    offerId: offerId,
    name: offerId,
    kind: OfferProgressKind.subtotal,
    currentValue: 2100,
    targetValue: 2100 + remaining,
    remainingValue: remaining,
    reward: OfferRewardEntity(type: reward),
  );

  CartEntity cartWith({
    CartCouponEntity? coupon,
    CartTotalsEntity totals = totals,
    List<CartOfferProgressEntity> offerProgress =
        const <CartOfferProgressEntity>[],
    CartLoyaltyEntity loyalty = const CartLoyaltyEntity(),
  }) => CartEntity(
    itemCount: 3,
    lines: lines,
    totals: totals,
    coupon: coupon,
    offerProgress: offerProgress,
    loyalty: loyalty,
  );

  CartSnapshot snapshotOf(CartEntity cart) =>
      CartSnapshot(cart: cart, isRestored: true, revision: ++revision);

  String iso(String code) => Formatters.isolate(code);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()..snapshot = snapshotOf(cartWith());
    cart = null;
    checkoutCubit = buildCheckoutCubit(FakeCheckoutRepository());
    session = buildSessionCubit();
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await checkoutCubit.close();
    await cart?.close();
    await session.close();
    await cartRepository.dispose();
  });

  /// A loaded offers cubit over [offers].
  Future<CheckoutOffersCubit> offersOf(
    WidgetTester tester,
    List<OfferEntity> offers,
  ) async {
    final cubit = buildOffersCubit(
      FakeCheckoutCatalogRepository(offers: offers),
    );
    addTearDown(cubit.close);
    await tester.runAsync(cubit.load);
    return cubit;
  }

  Future<void> pump(
    WidgetTester tester, {
    CheckoutOffersCubit? offers,
    List<RouteBase> extraRoutes = const <RouteBase>[],
    Locale locale = checkoutEn,
    Size size = const Size(480, 2400),
    double textScale = 1,
  }) async {
    await tester.runAsync(() async {
      cart = buildCartCubit(cartRepository);
      await Future<void>.delayed(Duration.zero);
    });
    await pumpCheckoutSection(
      tester,
      const CheckoutSavingsSection(),
      cart: cartCubit(),
      checkout: checkoutCubit,
      session: session,
      offers: offers,
      extraRoutes: extraRoutes,
      locale: locale,
      size: size,
      textScale: textScale,
    );
  }

  /// Pushes [cart] the way the repository stream delivers it.
  Future<void> push(WidgetTester tester, CartEntity cart) =>
      tester.runAsync(() async {
        cartRepository.push(snapshotOf(cart));
        await Future<void>.delayed(Duration.zero);
      });

  Future<void> emit(WidgetTester tester, CartEntity cart) async {
    await push(tester, cart);
    await tester.pumpAndSettle();
  }

  Finder tagText(String text) => find.descendant(
    of: find.byType(CheckoutUnlockTag),
    matching: find.text(text),
  );

  Iterable<double> tagScales(WidgetTester tester) => tester
      .widgetList<ScaleTransition>(
        find.descendant(
          of: find.byType(CheckoutUnlockTag),
          matching: find.byType(ScaleTransition),
        ),
      )
      .map((transition) => transition.scale.value);

  Finder countUp() => find.descendant(
    of: find.byType(CheckoutSavingsFigure),
    matching: find.byType(TweenAnimationBuilder<double>),
  );

  group('the coupons-and-offers figure', () {
    testWidgets('says "Add a code" with nothing applied', (tester) async {
      await pump(tester);

      expect(find.text('Instant savings'), findsOneWidget);
      expect(find.text('Coupons & offers'), findsOneWidget);
      expect(find.text('Add a code'), findsOneWidget);
    });

    testWidgets('reads the server totals: code, code with no saving, '
        'offers, code + offers', (tester) async {
      await pump(tester);

      await emit(
        tester,
        cartWith(
          coupon: const CartCouponEntity(code: 'SAVE10', discountFils: 500),
          totals: totals.copyWithDiscounts(coupon: 500),
        ),
      );
      expect(find.text('${iso('SAVE10')} · saved KD 0.500'), findsOneWidget);

      await emit(
        tester,
        cartWith(coupon: const CartCouponEntity(code: 'SAVE10')),
      );
      expect(
        find.text('${iso('SAVE10')} · no saving on this basket'),
        findsOneWidget,
      );

      await emit(
        tester,
        cartWith(totals: totals.copyWithDiscounts(offer: 300)),
      );
      expect(find.text('Offers · saved KD 0.300'), findsOneWidget);

      await emit(
        tester,
        cartWith(
          coupon: const CartCouponEntity(code: 'SAVE10', discountFils: 500),
          totals: totals.copyWithDiscounts(coupon: 500, offer: 300),
        ),
      );
      // The coupon and the offers together; points have their own row.
      expect(find.text('Saved KD 0.800'), findsOneWidget);
    });
  });

  group('the unlock tag', () {
    testWidgets('is worded from the reward, with the cap', (tester) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(offerProgress: [progress('pct', 1500)]),
      );
      await pump(tester, offers: await offersOf(tester, [percentOffer]));

      expect(
        tagText('Add KD 1.500 for 10% off (up to KD 3.000)'),
        findsOneWidget,
      );
    });

    testWidgets('a fixed discount says what comes off', (tester) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(offerProgress: [progress('amt', 1500)]),
      );
      await pump(tester, offers: await offersOf(tester, [fixedOffer]));

      expect(tagText('Add KD 1.500 for KD 1.000 off'), findsOneWidget);
    });

    testWidgets('skips non-stackable, other-branch and unknown offers', (
      tester,
    ) async {
      await checkoutCubit.start(defaultAddressId: 'a1'); // serving branch b1
      cartRepository.snapshot = snapshotOf(
        cartWith(
          offerProgress: [
            progress('solo', 300),
            progress('far', 400),
            progress('ghost', 200), // not in the store's list
            progress('near', 900),
          ],
        ),
      );
      await pump(
        tester,
        offers: await offersOf(tester, [soloOffer, elsewhereOffer, hereOffer]),
      );

      // The nearer ones are not honest to advertise; the branch's own is.
      expect(tagText('Add KD 0.900 for KD 0.500 off'), findsOneWidget);
      expect(find.byType(CheckoutRedTag), findsOneWidget);
    });

    testWidgets('free delivery shows until delivery is free already', (
      tester,
    ) async {
      final free = progress('free', 700, reward: OfferRewardType.freeDelivery);
      cartRepository.snapshot = snapshotOf(cartWith(offerProgress: [free]));
      await pump(tester, offers: await offersOf(tester, [freeOffer]));
      expect(tagText('Add KD 0.700 for free delivery'), findsOneWidget);

      await emit(
        tester,
        cartWith(
          offerProgress: [free],
          totals: totals.copyWithDiscounts(freeDelivery: true),
        ),
      );
      expect(find.byType(CheckoutRedTag), findsNothing);
    });

    testWidgets('no tag without the store list (terms unknown)', (
      tester,
    ) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(offerProgress: [progress('pct', 1500)]),
      );
      await pump(tester);

      expect(find.byType(CheckoutRedTag), findsNothing);
    });
  });

  group('motion', () {
    testWidgets('CT-V1 a code applied after open: the tag pops and the '
        'saving counts up once', (tester) async {
      await pump(tester, offers: await offersOf(tester, [percentOffer]));
      expect(countUp(), findsNothing);

      await push(
        tester,
        cartWith(
          coupon: const CartCouponEntity(code: 'SAVE', discountFils: 500),
          totals: totals.copyWithDiscounts(coupon: 500),
          offerProgress: [progress('pct', 1500)],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tagScales(tester).any((s) => s > 0 && s < 1), isTrue);
      expect(countUp(), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('${iso('SAVE')} · saved KD 0.500'), findsOneWidget);
      // Read once, as the final figure (inside the row's merged label).
      expect(find.bySemanticsLabel(RegExp('saved KD 0.500')), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('CT-V2 a coupon already applied at open plays nothing', (
      tester,
    ) async {
      cartRepository.snapshot = snapshotOf(
        cartWith(
          coupon: const CartCouponEntity(code: 'SAVE', discountFils: 500),
          totals: totals.copyWithDiscounts(coupon: 500),
          offerProgress: [progress('pct', 1500)],
        ),
      );
      await pump(tester, offers: await offersOf(tester, [percentOffer]));

      expect(find.text('${iso('SAVE')} · saved KD 0.500'), findsOneWidget);
      expect(countUp(), findsNothing);
      expect(tagScales(tester).every((s) => s == 1), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('CT-V3 a change made while covered plays when revealed', (
      tester,
    ) async {
      await pump(
        tester,
        offers: await offersOf(tester, [percentOffer]),
        extraRoutes: [
          GoRoute(
            path: '/cover',
            builder: (_, _) => const Scaffold(body: SizedBox.expand()),
          ),
        ],
      );
      final router = GoRouter.of(
        tester.element(find.byType(CheckoutSavingsSection)),
      );
      unawaited(router.push('/cover'));
      await tester.pumpAndSettle();

      await push(tester, cartWith(offerProgress: [progress('pct', 1500)]));
      await tester.pump();
      await tester.pump();
      // Nothing ticks under the cover.
      expect(tester.binding.transientCallbackCount, 0);

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tagScales(tester).any((s) => s < 1), isTrue);
      await tester.pumpAndSettle();
      expect(
        tagText('Add KD 1.500 for 10% off (up to KD 3.000)'),
        findsOneWidget,
      );
    });
  });

  group('the points row', () {
    void signIn(int points) => session.signedIn(
      AuthCustomerEntity(
        id: 'c1',
        phone: '+96550000000',
        loyaltyPoints: points,
      ),
    );

    testWidgets('a guest sees no points row', (tester) async {
      await checkoutCubit.start();
      await pump(tester);

      expect(find.text('Points'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('a customer who can redeem switches the points on', (
      tester,
    ) async {
      await checkoutCubit.start(); // the rules: from 100 points, 1 fils each
      signIn(150);
      await pump(tester);

      expect(find.text('Points'), findsOneWidget);
      expect(find.text('Use 150 points · worth KD 0.150'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(cartRepository.calls, contains('applyLoyalty:150'));
    });

    testWidgets('worth is capped at what the goods still cost', (tester) async {
      await checkoutCubit.start();
      signIn(5000);
      // 2.100 of goods less a 0.500 coupon: the points can pay 1.600.
      cartRepository.snapshot = snapshotOf(
        cartWith(
          coupon: const CartCouponEntity(code: 'SAVE', discountFils: 500),
          totals: totals.copyWithDiscounts(coupon: 500),
        ),
      );
      await pump(tester);

      expect(find.text('Use 1600 points · worth KD 1.600'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(cartRepository.calls, contains('applyLoyalty:1600'));
    });

    testWidgets('under the minimum: a plain line, no switch', (tester) async {
      await checkoutCubit.start();
      signIn(50);
      await pump(tester);

      expect(find.text('You have 50 points · redeem from 100'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('applied points say what they saved and switch off', (
      tester,
    ) async {
      await checkoutCubit.start();
      signIn(150);
      cartRepository.snapshot = snapshotOf(
        cartWith(
          loyalty: const CartLoyaltyEntity(
            pointsApplied: 150,
            discountFils: 150,
          ),
        ),
      );
      await pump(tester);

      expect(find.text('150 points · saved KD 0.150'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(cartRepository.calls, contains('removeLoyalty'));
    });

    testWidgets('rests while a cart action runs', (tester) async {
      await checkoutCubit.start();
      signIn(150);
      await pump(tester);

      final gate = Completer<void>();
      cartRepository.gate = gate;
      await tester.runAsync(() async {
        unawaited(cartCubit().applyCoupon('SAVE'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

      await tester.runAsync(() async {
        gate.complete();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    });

    testWidgets('a refused redeem shows no snack of its own', (tester) async {
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
      await checkoutCubit.start();
      signIn(150);
      await pump(tester);

      cartRepository.failure = const ServerFailure('No points for you');
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(cartRepository.calls, contains('applyLoyalty:150'));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('No points for you'), findsNothing);
      // One selection click for the one toggle.
      expect(haptics, <Object?>['HapticFeedbackType.selectionClick']);
    });
  });

  testWidgets('fits a 360 dp phone at 1.3× text in Arabic', (tester) async {
    await checkoutCubit.start();
    session.signedIn(
      const AuthCustomerEntity(
        id: 'c1',
        phone: '+96550000000',
        loyaltyPoints: 150,
      ),
    );
    cartRepository.snapshot = snapshotOf(
      cartWith(
        coupon: const CartCouponEntity(code: 'SAVE10', discountFils: 500),
        totals: totals.copyWithDiscounts(coupon: 500, offer: 300),
        offerProgress: [progress('pct', 1500)],
      ),
    );
    await pump(
      tester,
      offers: await offersOf(tester, [percentOffer]),
      locale: checkoutAr,
      size: const Size(360, 800),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('توفير فوري'), findsOneWidget);
    expect(find.text('الكوبونات والعروض'), findsOneWidget);
    expect(find.byType(CheckoutRedTag), findsOneWidget);
    expect(find.text('النقاط'), findsOneWidget);
  });

  group('the coupons row', () {
    List<RouteBase> vouchersStub() => [
      GoRoute(
        path: Routes.checkoutVouchers,
        builder: (_, state) => Scaffold(body: Text('vouchers:${state.extra}')),
      ),
    ];

    testWidgets('opens the vouchers page with the serving branch', (
      tester,
    ) async {
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pump(tester, extraRoutes: vouchersStub());

      await tester.tap(find.text('Coupons & offers'));
      await tester.pumpAndSettle();
      expect(find.text('vouchers:b1'), findsOneWidget);
    });

    testWidgets('no destination yet: no branch', (tester) async {
      await checkoutCubit.start();
      await pump(tester, extraRoutes: vouchersStub());

      await tester.tap(find.text('Coupons & offers'));
      await tester.pumpAndSettle();
      expect(find.text('vouchers:null'), findsOneWidget);
    });
  });
}

extension on CartTotalsEntity {
  /// These totals with the server's discounts (and free delivery) set.
  CartTotalsEntity copyWithDiscounts({
    int coupon = 0,
    int offer = 0,
    bool freeDelivery = false,
  }) => CartTotalsEntity(
    subtotalFils: subtotalFils,
    couponDiscountFils: coupon,
    offerDiscountFils: offer,
    discountFils: coupon + offer,
    deliveryFeeFils: freeDelivery ? 0 : deliveryFeeFils,
    freeDelivery: freeDelivery,
    totalFils:
        subtotalFils - coupon - offer + (freeDelivery ? 0 : deliveryFeeFils),
    baseDeliveryFeeFils: baseDeliveryFeeFils,
  );
}
