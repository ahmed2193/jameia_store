// "Order totals": the scalloped receipt. Every figure is the server's (or a
// sum of them in `CartSavings`); these tests pin which line shows what, when
// the optional lines open, what hides while the cart re-prices, and that the
// scalloped edge is not rebuilt while a line opens.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_applied_offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_loyalty_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:hero_mart/src/core/widgets/hero_money_text.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_offers_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_info_sheet.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_receipt.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_receipt_border.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';
import 'fake_checkout_repository.dart';

/// 2 × rice at 0.600 (list 0.750) and 1 × oil at 0.900: 0.300 saved on
/// promo items.
const List<CartLineEntity> _saleLines = <CartLineEntity>[
  CartLineEntity(
    key: 'l1',
    product: testProduct,
    quantity: 2,
    unitPriceFils: 600,
    compareAtFils: 750,
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

/// The same basket at full price.
const List<CartLineEntity> _plainLines = <CartLineEntity>[
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

/// 2.100 of goods + 0.500 delivery.
const CartTotalsEntity _priced = CartTotalsEntity(
  subtotalFils: 2100,
  deliveryFeeFils: 500,
  baseDeliveryFeeFils: 500,
  totalFils: 2600,
);

const CartAppliedOfferEntity _freeDeliveryOffer = CartAppliedOfferEntity(
  offerId: 'fd',
  name: 'Free delivery weekend',
  discountFils: 650,
  reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
);

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late FakeCheckoutRepository checkoutRepository;
  late CheckoutCubit checkoutCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = const CartSnapshot(isRestored: true);
    cartCubit = buildCartCubit(cartRepository);
    checkoutRepository = FakeCheckoutRepository();
    checkoutCubit = buildCheckoutCubit(checkoutRepository);
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await checkoutCubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  /// Puts [cart] on the (already started) cart and starts checkout on the
  /// saved address (priced) unless [quote] is off. Call before [pump]: the
  /// pump lets the cart take the snapshot.
  Future<void> open(CartEntity cart, {bool quote = true}) async {
    cartRepository.push(CartSnapshot(cart: cart, isRestored: true));
    await checkoutCubit.start(defaultAddressId: quote ? 'a1' : null);
  }

  /// Pushes a cart snapshot the way the repository stream delivers it.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  Future<void> pump(
    WidgetTester tester, {
    AuthSessionCubit? session,
    CheckoutOffersCubit? offers,
    Locale locale = checkoutEn,
  }) => pumpCheckoutSection(
    tester,
    const CheckoutReceipt(),
    cart: cartCubit,
    checkout: checkoutCubit,
    session: session,
    offers: offers,
    locale: locale,
  );

  /// The struck (was-) amounts on the receipt.
  Finder struck() => find.byWidgetPredicate(
    (widget) => widget is HeroMoneyText && widget.strike,
  );

  group('delivery', () {
    testWidgets('free delivery: "Free", the waived fee struck, counted '
        'in the savings', (tester) async {
      await open(
        const CartEntity(
          itemCount: 3,
          lines: _plainLines,
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            freeDelivery: true,
            baseDeliveryFeeFils: 650,
            totalFils: 2100,
          ),
        ),
      );
      await pump(tester);

      expect(find.text('Free'), findsOneWidget);
      expect(struck(), findsOneWidget);
      expect(
        find.descendant(of: struck(), matching: find.text('KD 0.650')),
        findsOneWidget,
      );
      expect(find.text('KD 0.650 off applied'), findsOneWidget);
    });

    testWidgets('an applied free-delivery offer the server counts as a '
        'discount: named, never struck, and the rows add up', (tester) async {
      // Shape 1: the fee stays on the bill and the offer takes it off.
      await open(
        const CartEntity(
          itemCount: 3,
          lines: _plainLines,
          appliedOffers: <CartAppliedOfferEntity>[_freeDeliveryOffer],
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            offerDiscountFils: 650,
            discountFils: 650,
            deliveryFeeFils: 650,
            baseDeliveryFeeFils: 650,
            freeDelivery: true,
            totalFils: 2100,
          ),
        ),
      );
      await pump(tester);

      expect(find.text('Free delivery weekend applied'), findsOneWidget);
      expect(struck(), findsNothing);
      // 2.100 + 0.650 − 0.650 = 2.100: the fee is shown, not "Free".
      expect(find.text('Free'), findsNothing);
      expect(find.text('KD 0.650'), findsOneWidget);
      expect(find.text('- KD 0.650'), findsOneWidget);
      expect(find.text('KD 2.100'), findsNWidgets(2));
    });

    testWidgets('the same offer with the fee already zeroed: "Free", still '
        'not struck twice', (tester) async {
      // Shape 2: no fee on the bill, the offer still reports its discount.
      await open(
        const CartEntity(
          itemCount: 3,
          lines: _plainLines,
          appliedOffers: <CartAppliedOfferEntity>[_freeDeliveryOffer],
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            offerDiscountFils: 650,
            discountFils: 650,
            baseDeliveryFeeFils: 650,
            freeDelivery: true,
            totalFils: 1450,
          ),
        ),
      );
      await pump(tester);

      expect(find.text('Free'), findsOneWidget);
      expect(struck(), findsNothing);
      expect(find.text('- KD 0.650'), findsOneWidget);
      expect(find.text('KD 1.450'), findsOneWidget);
      expect(find.text('KD 0.650 off applied'), findsOneWidget);
    });

    testWidgets('"free" with a fee still charged shows the fee', (
      tester,
    ) async {
      await open(
        const CartEntity(
          itemCount: 3,
          lines: _plainLines,
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            freeDelivery: true,
            deliveryFeeFils: 500,
            baseDeliveryFeeFils: 500,
            totalFils: 2600,
          ),
        ),
      );
      await pump(tester);

      expect(find.text('Free'), findsNothing);
      expect(find.text('KD 0.500'), findsOneWidget);
      expect(struck(), findsNothing);
    });

    testWidgets('Pro free delivery says it is the membership', (tester) async {
      checkoutRepository.rules = const CheckoutStoreRules(
        storeName: 'Hero',
        proFreeDelivery: true,
      );
      await open(
        const CartEntity(
          itemCount: 3,
          lines: _plainLines,
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            freeDelivery: true,
            baseDeliveryFeeFils: 500,
            totalFils: 2100,
          ),
        ),
      );
      final session = buildSessionCubit()
        ..signedIn(
          const AuthCustomerEntity(
            id: 'c1',
            phone: '+96550000000',
            isPro: true,
          ),
        );
      addTearDown(session.close);
      await pump(tester, session: session);

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Free delivery with Hero Pro'), findsOneWidget);
    });

    testWidgets('short of a free-delivery offer: what is missing', (
      tester,
    ) async {
      await open(
        const CartEntity(
          itemCount: 3,
          lines: _plainLines,
          offerProgress: <CartOfferProgressEntity>[
            CartOfferProgressEntity(
              offerId: 'fd',
              name: 'Free delivery over 2.500',
              kind: OfferProgressKind.subtotal,
              currentValue: 2100,
              targetValue: 2500,
              remainingValue: 400,
              reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
            ),
          ],
          totals: _priced,
        ),
      );
      final offers = buildOffersCubit(
        FakeCheckoutCatalogRepository(
          offers: const <OfferEntity>[
            OfferEntity(
              id: 'fd',
              name: 'Free delivery over 2.500',
              minSubtotalFils: 2500,
              rewardType: OfferRewardType.freeDelivery,
              stackable: true,
            ),
          ],
        ),
      );
      addTearDown(offers.close);
      await offers.load();
      await pump(tester, offers: offers);

      expect(find.text('Add KD 0.400 more for free delivery'), findsOneWidget);
    });

    testWidgets('pickup: "Pickup", "—" until a branch, then "No fee"', (
      tester,
    ) async {
      await open(
        const CartEntity(
          itemCount: 3,
          fulfillmentMode: FulfillmentMode.pickup,
          lines: _plainLines,
          totals: CartTotalsEntity(subtotalFils: 2100, totalFils: 2100),
        ),
        quote: false,
      );
      await checkoutCubit.setMode(FulfillmentMode.pickup);
      await pump(tester);

      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Delivery fee'), findsNothing);
      expect(find.text('—'), findsNWidgets(2));

      await checkoutCubit.selectBranch('b1');
      await tester.pumpAndSettle();

      expect(find.text('No fee'), findsOneWidget);
      expect(find.text('—'), findsNothing);
      expect(find.text('KD 2.100'), findsNWidgets(2));
    });
  });

  group('lines', () {
    testWidgets('sale lines: the promo line and the struck list subtotal', (
      tester,
    ) async {
      await open(
        const CartEntity(itemCount: 3, lines: _saleLines, totals: _priced),
      );
      await pump(tester);

      expect(find.text('Promo items: KD 0.300 off applied'), findsOneWidget);
      expect(
        find.descendant(of: struck(), matching: find.text('KD 2.400')),
        findsOneWidget,
      );
      expect(find.text('KD 0.300 off applied'), findsOneWidget);
    });

    testWidgets('express, offers, coupon and points lines show only while '
        'they are not zero', (tester) async {
      await open(
        const CartEntity(itemCount: 3, lines: _plainLines, totals: _priced),
      );
      await pump(tester);

      expect(find.text('Express delivery fee'), findsNothing);
      expect(find.text('Offers'), findsNothing);
      expect(find.text('Coupon SAVE'), findsNothing);
      expect(find.text('Points (150)'), findsNothing);

      await emit(
        tester,
        const CartSnapshot(
          isRestored: true,
          revision: 1,
          cart: CartEntity(
            itemCount: 3,
            lines: _plainLines,
            coupon: CartCouponEntity(code: 'SAVE', discountFils: 500),
            loyalty: CartLoyaltyEntity(pointsApplied: 150, discountFils: 150),
            expressSelected: true,
            totals: CartTotalsEntity(
              subtotalFils: 2100,
              couponDiscountFils: 500,
              loyaltyDiscountFils: 150,
              offerDiscountFils: 200,
              discountFils: 850,
              deliveryFeeFils: 1000,
              baseDeliveryFeeFils: 500,
              expressSurchargeFils: 500,
              totalFils: 2250,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Express delivery fee'), findsOneWidget);
      // The delivery line leaves the surcharge to its own line.
      expect(find.text('KD 0.500'), findsNWidgets(2));
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('- KD 0.200'), findsOneWidget);
      expect(find.text('Coupon SAVE'), findsOneWidget);
      expect(find.text('- KD 0.500'), findsOneWidget);
      expect(find.text('Points (150)'), findsOneWidget);
      expect(find.text('- KD 0.150'), findsOneWidget);
      expect(find.text('KD 2.250'), findsOneWidget);

      await emit(
        tester,
        const CartSnapshot(
          isRestored: true,
          revision: 2,
          cart: CartEntity(itemCount: 3, lines: _plainLines, totals: _priced),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Express delivery fee'), findsNothing);
      expect(find.text('Offers'), findsNothing);
      expect(find.text('Coupon SAVE'), findsNothing);
      expect(find.text('Points (150)'), findsNothing);
    });

    testWidgets('while the cart re-prices, "off applied" hides and the promo '
        'line stays', (tester) async {
      await open(
        const CartEntity(itemCount: 3, lines: _saleLines, totals: _priced),
      );
      await pump(tester);
      expect(find.text('KD 0.300 off applied'), findsOneWidget);

      await emit(
        tester,
        const CartSnapshot(
          isRestored: true,
          hasPendingChanges: true,
          revision: 1,
          cart: CartEntity(itemCount: 3, lines: _saleLines, totals: _priced),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Updating…'), findsOneWidget);
      expect(find.text('KD 0.300 off applied'), findsNothing);
      expect(find.text('KD 2.600'), findsNothing);
      expect(find.text('Promo items: KD 0.300 off applied'), findsOneWidget);
    });

    testWidgets('below the minimum order: how much is missing', (tester) async {
      await open(
        const CartEntity(
          itemCount: 3,
          lines: _plainLines,
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            deliveryFeeFils: 500,
            totalFils: 2600,
            minOrderFils: 3000,
            meetsMinOrder: false,
          ),
        ),
      );
      await pump(tester);

      expect(
        find.text('Add KD 0.900 to reach the minimum order'),
        findsOneWidget,
      );
    });

    testWidgets('the ⓘ explains the subtotal in a sheet', (tester) async {
      await open(
        const CartEntity(itemCount: 3, lines: _plainLines, totals: _priced),
      );
      await pump(tester);

      await tester.tap(find.bySemanticsLabel("What's in the subtotal"));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutInfoSheet), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutInfoSheet), findsNothing);
    });
  });

  testWidgets('Arabic: the title, and money as one left-to-right run', (
    tester,
  ) async {
    Intl.defaultLocale = 'ar';
    await open(
      const CartEntity(itemCount: 3, lines: _plainLines, totals: _priced),
    );
    await pump(tester, locale: checkoutAr);

    expect(find.text('إجمالي الطلب'), findsOneWidget);
    final subtotal = find
        .descendant(
          of: find.byType(CheckoutReceipt),
          matching: find.byType(HeroMoneyText),
        )
        .first;
    final run = find.descendant(
      of: subtotal,
      matching: find.byType(Directionality),
    );
    expect(tester.widget<Directionality>(run).textDirection, TextDirection.ltr);
    expect(
      find.descendant(of: subtotal, matching: find.text('د.ك 2.100')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the scalloped edge is not rebuilt while a line opens', (
    tester,
  ) async {
    await open(
      const CartEntity(itemCount: 3, lines: _plainLines, totals: _priced),
    );
    await pump(tester);
    final closed = tester.getSize(find.byType(CheckoutReceipt));
    final builds = CheckoutReceiptBorder.debugPathBuilds;

    await emit(
      tester,
      const CartSnapshot(
        isRestored: true,
        revision: 1,
        cart: CartEntity(
          itemCount: 3,
          lines: _plainLines,
          coupon: CartCouponEntity(code: 'SAVE', discountFils: 500),
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            couponDiscountFils: 500,
            discountFils: 500,
            deliveryFeeFils: 500,
            baseDeliveryFeeFils: 500,
            totalFils: 2100,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-open: the card is taller than before, painted every frame.
    final opening = tester.getSize(find.byType(CheckoutReceipt));
    expect(opening.height, greaterThan(closed.height));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(CheckoutReceipt)).height,
      greaterThan(opening.height),
    );
    expect(CheckoutReceiptBorder.debugPathBuilds, builds);

    // A new width is a new pair of strips (the counter is not idle).
    tester.view.physicalSize = const Size(400, 2400);
    await tester.pumpAndSettle();
    expect(CheckoutReceiptBorder.debugPathBuilds, builds + 1);
  });
}
