// The restyled cart (white page, hairline cards, pinned bar) on both hosts:
// what it shows in English and Arabic, that it fits a 360 dp phone at 1.3×
// text, the options card's hairlines, the stepper, the checkout bar's reason
// and total, the coupon sheet's ✕, and the motion — lines that fold away or
// open in, big changes that land at once, the rolling bar total, the sync
// banner that folds, and the same end state under reduced motion.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_ref.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_loyalty_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:jameia_mart/src/core/widgets/jameia_close_button.dart';
import 'package:jameia_mart/src/core/widgets/jameia_title_bar.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_lines_layout.dart';
import 'package:jameia_mart/src/features/cart/presentation/pages/cart_preview_page.dart';
import 'package:jameia_mart/src/features/cart/presentation/pages/cart_tab_page.dart';
import 'package:jameia_mart/src/features/cart/presentation/widgets/cart/cart_checkout_bar.dart';
import 'package:jameia_mart/src/features/cart/presentation/widgets/cart/cart_coupon_row.dart';
import 'package:jameia_mart/src/features/cart/presentation/widgets/cart/cart_coupon_sheet.dart';
import 'package:jameia_mart/src/features/cart/presentation/widgets/cart/cart_line_tile.dart';
import 'package:jameia_mart/src/features/cart/presentation/widgets/cart/cart_options_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_page_harness.dart';
import 'cart_test_fixtures.dart';
import 'fake_cart_repository.dart';

CatalogProductEntity _product(String id, String name) =>
    CatalogProductEntity(id: id, slug: id, name: name);

const CartLineEntity _rice = CartLineEntity(
  key: 'l1',
  product: testProduct,
  quantity: 1,
  unitPriceFils: 1500,
  lineTotalFils: 1500,
);
const CartLineEntity _oil = CartLineEntity(
  key: 'l2',
  product: otherProduct,
  quantity: 1,
  unitPriceFils: 2500,
  lineTotalFils: 2500,
);

/// Every block of the page at once: a deal line with a long name and a
/// long variant, a blocked line, a line at its stock cap, a gift, two offer
/// bars, coupon + points + express, and a minimum order not reached.
CartEntity _richCart() => CartEntity(
  itemCount: 6,
  lines: <CartLineEntity>[
    CartLineEntity(
      key: 'r1',
      product: _product(
        'p10',
        'Extra virgin cold-pressed olive oil from the northern hills',
      ),
      quantity: 2,
      unitPriceFils: 12500,
      compareAtFils: 15000,
      lineTotalFils: 25000,
      variantId: 'v1',
      variantName: 'Family bottle, 2 litres, glass',
    ),
    CartLineEntity(
      key: 'r2',
      product: _product('p11', 'Fresh strawberries'),
      quantity: 1,
      unitPriceFils: 1250,
      lineTotalFils: 1250,
      issue: CartLineIssue.outOfStock,
    ),
    CartLineEntity(
      key: 'r3',
      product: _product('p12', 'Sparkling water 24 × 330 ml'),
      quantity: 3,
      maxQuantity: 3,
      unitPriceFils: 3750,
      lineTotalFils: 11250,
    ),
  ],
  offerLines: <CartOfferLineEntity>[
    CartOfferLineEntity(
      key: 'g1',
      offerId: 'o1',
      offerName: 'The big weekend basket deal',
      quantity: 1,
      product: _product('p20', 'Reusable tote bag'),
    ),
  ],
  offerProgress: const <CartOfferProgressEntity>[
    CartOfferProgressEntity(
      offerId: 'o2',
      name: 'Free delivery',
      kind: OfferProgressKind.subtotal,
      currentValue: 37500,
      targetValue: 50000,
      remainingValue: 12500,
      reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
    ),
    CartOfferProgressEntity(
      offerId: 'o3',
      name: 'Ten off',
      kind: OfferProgressKind.item,
      currentValue: 3,
      targetValue: 3,
      reward: OfferRewardEntity(
        type: OfferRewardType.percentageDiscount,
        percent: 10,
      ),
    ),
  ],
  coupon: const CartCouponEntity(code: 'WEEKEND10', discountFils: 500),
  loyalty: const CartLoyaltyEntity(pointsApplied: 120, discountFils: 300),
  expressOffered: true,
  expressEtaMinutes: 30,
  expressSurchargeOfferedFils: 500,
  totals: const CartTotalsEntity(
    subtotalFils: 37500,
    offerDiscountFils: 200,
    couponDiscountFils: 500,
    loyaltyDiscountFils: 300,
    discountFils: 1000,
    deliveryFeeFils: 1000,
    expressSurchargeFils: 500,
    totalFils: 37500,
    minOrderFils: 50000,
    meetsMinOrder: false,
    etaMinutes: 45,
  ),
);

CartSnapshot _snapshot(CartEntity cart, {int revision = 1}) =>
    CartSnapshot(cart: cart, isRestored: true, revision: revision);

CartEntity _cartOf(
  List<CartLineEntity> lines, {
  CartTotalsEntity totals = const CartTotalsEntity(totalFils: 3000),
  bool express = false,
  CartLoyaltyEntity loyalty = const CartLoyaltyEntity(),
}) => CartEntity(
  itemCount: lines.fold<int>(0, (sum, line) => sum + line.quantity),
  lines: List<CartLineEntity>.of(lines),
  expressOffered: express,
  expressEtaMinutes: express ? 30 : null,
  loyalty: loyalty,
  totals: totals,
);

void main() {
  late FakeCartRepository repository;
  late CartCubit cartCubit;
  late AuthSessionCubit session;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    session = buildGuestSession();
    repository = FakeCartRepository();
    cartCubit = buildCartCubit(repository);
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await session.close();
    await cartCubit.close();
    await repository.dispose();
  });

  /// Pumps [home] (the Cart tab by default) — or [router] — over the cart.
  Future<void> pump(
    WidgetTester tester,
    CartSnapshot snapshot, {
    Widget? home,
    GoRouter? router,
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool reduceMotion = false,
  }) => pumpCartHost(
    tester,
    repository: repository,
    cart: cartCubit,
    session: session,
    snapshot: snapshot,
    home: home ?? CartTabPage(onBrowse: () {}),
    router: router,
    locale: locale,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: child!,
    ),
    // Real time for the translation file of a locale not read yet.
    loadDelay: const Duration(milliseconds: 100),
  );

  Future<void> emit(WidgetTester tester, CartSnapshot snapshot) =>
      emitCartSnapshot(tester, repository, snapshot);

  void phone(WidgetTester tester, {double height = 800}) {
    tester.view.physicalSize = Size(360, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder optionsHairlines() => find.descendant(
    of: find.byType(CartOptionsSection),
    matching: find.byType(Divider),
  );

  group('renders', () {
    testWidgets('the Cart tab: header, rows, options, summary and bar', (
      tester,
    ) async {
      phone(tester, height: 2400);
      await pump(tester, _snapshot(_richCart()));

      expect(find.text('6 items'), findsOneWidget);
      expect(find.text('Clear cart'), findsOneWidget);
      expect(find.text('Fresh strawberries'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget); // the blocked line
      expect(find.text('Max 3'), findsOneWidget);
      expect(find.text('Reusable tote bag'), findsOneWidget);
      expect(find.text('Offers & options'), findsOneWidget);
      expect(find.text('WEEKEND10 applied'), findsOneWidget);
      expect(find.text('Express delivery'), findsOneWidget);
      expect(find.text('Payment summary'), findsOneWidget);
      // The summary's row; the bar leads with the basket instead of a label.
      expect(find.text('Total'), findsOneWidget);
      // The deals strip over the bar: the next offer to unlock, "Add item".
      expect(
        find.text('Add KD 12.500 more to get free delivery'),
        findsOneWidget,
      );
      expect(find.text('Add item'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('the pushed cart: title bar, same header, no bar action', (
      tester,
    ) async {
      await pump(
        tester,
        _snapshot(_cartOf(const [_rice, _oil])),
        home: const CartPreviewPage(),
      );

      expect(
        find.descendant(
          of: find.byType(JameiaTitleBar),
          matching: find.text('Cart'),
        ),
        findsOneWidget,
      );
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('Clear cart'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(JameiaTitleBar),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
    });

    testWidgets('Arabic: a right-to-left page with money in one LTR run', (
      tester,
    ) async {
      Intl.defaultLocale = 'ar';
      await pump(
        tester,
        _snapshot(_cartOf(const [_rice])),
        locale: const Locale('ar'),
      );

      expect(
        Directionality.of(tester.element(find.text('Basmati rice'))),
        TextDirection.rtl,
      );
      final price = find.text('د.ك 1.500').first;
      final run = tester.widget<Directionality>(
        find.ancestor(of: price, matching: find.byType(Directionality)).first,
      );
      expect(run.textDirection, TextDirection.ltr);
    });

    for (final locale in const <Locale>[Locale('en'), Locale('ar')]) {
      testWidgets('fits 360 dp at 1.3× text (${locale.languageCode})', (
        tester,
      ) async {
        phone(tester);
        if (locale.languageCode == 'ar') Intl.defaultLocale = 'ar';
        await pump(
          tester,
          _snapshot(_richCart()),
          locale: locale,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);

        // Lay out everything below the fold too.
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -3000),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the options card draws hairlines only between shown rows', (
    tester,
  ) async {
    phone(tester, height: 1600);
    await pump(tester, _snapshot(_cartOf(const [_rice])));
    expect(optionsHairlines(), findsNothing); // coupon only

    await emit(
      tester,
      _snapshot(_cartOf(const [_rice], express: true), revision: 2),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(optionsHairlines(), findsOneWidget); // coupon + express

    await emit(
      tester,
      _snapshot(
        _cartOf(
          const [_rice],
          express: true,
          loyalty: const CartLoyaltyEntity(pointsApplied: 50, discountFils: 50),
        ),
        revision: 3,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(optionsHairlines(), findsNWidgets(2)); // + points
  });

  testWidgets('the stepper: a bin at 1 that removes, no "+" at the cap', (
    tester,
  ) async {
    await pump(
      tester,
      _snapshot(
        _cartOf(const [
          CartLineEntity(
            key: 'l1',
            product: testProduct,
            quantity: 1,
            maxQuantity: 1,
            unitPriceFils: 1500,
            lineTotalFils: 1500,
          ),
        ]),
      ),
    );

    expect(find.byTooltip('Remove'), findsOneWidget);
    expect(find.byTooltip('Decrease quantity'), findsNothing);
    final plus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_rounded),
    );
    expect(plus.onPressed, isNull);
    expect(find.text('Max 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pump();
    expect(repository.calls, contains('adjust:p1::-1'));
  });

  testWidgets('one selection haptic per stepper tap', (tester) async {
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
    await pump(tester, _snapshot(_cartOf(const [_rice])));

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();

    expect(haptics, <Object?>['HapticFeedbackType.selectionClick']);
    expect(repository.calls, contains('adjust:p1::1'));
  });

  testWidgets('below the minimum order: the reason, the total, no checkout', (
    tester,
  ) async {
    await pump(
      tester,
      _snapshot(
        _cartOf(
          const [_rice],
          totals: const CartTotalsEntity(
            subtotalFils: 1500,
            totalFils: 3000,
            minOrderFils: 5000,
            meetsMinOrder: false,
          ),
        ),
      ),
    );

    expect(
      find.text('Add KD 3.500 more to reach the minimum order'),
      findsOneWidget,
    );
    final semantics = tester.ensureSemantics();
    expect(
      find.descendant(
        of: find.byType(CartCheckoutBar),
        matching: find.bySemanticsLabel('KD 3.000'),
      ),
      findsOneWidget,
    );
    semantics.dispose();

    await tester.tap(find.text('Checkout'));
    await tester.pump(const Duration(milliseconds: 400)); // the refusal shake
    expect(repository.calls, isNot(contains('flush')));
  });

  testWidgets('the coupon sheet closes with its ✕', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => CartTabPage(onBrowse: () {}),
        ),
      ],
    );
    addTearDown(router.dispose);
    await pump(tester, _snapshot(_cartOf(const [_rice])), router: router);

    await tester.tap(find.text('Add a coupon code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CartCouponSheet), findsOneWidget);

    await tester.tap(find.byType(JameiaCloseButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CartCouponSheet), findsNothing);
  });

  group('CartLinesLayout / CartLinesChange', () {
    test('equal structure for a quantity change, gifts after lines', () {
      final one = CartLinesLayout.of(
        _richCart().copyWith(lines: [_rice, _oil]),
      );
      final two = CartLinesLayout.of(
        _richCart().copyWith(lines: [_rice.withQuantity(5), _oil]),
      );
      expect(one, two);
      expect(one.ids, <Object>[
        const CartLineRef('p1'),
        const CartLineRef('p2'),
        'offer:g1',
      ]);
    });

    test('removals, inserts and the kept order in list terms', () {
      final change = CartLinesChange(
        const <Object>['a', 'b', 'c', 'd'],
        const <Object>['a', 'c', 'e', 'd', 'f'],
      );
      expect(change.removed, <int>[1]);
      expect(change.added, <int>[2, 4]);
      expect(change.keptOrder, isTrue);
      expect(change.size, 3);
      expect(change.isReorder, isFalse);

      final reorder = CartLinesChange(
        const <Object>['a', 'b'],
        const <Object>['b', 'a'],
      );
      expect(reorder.isReorder, isTrue);
      expect(reorder.keptOrder, isFalse);

      final mixed = CartLinesChange(
        const <Object>['a', 'b', 'c'],
        const <Object>['c', 'a', 'x'],
      );
      expect(mixed.keptOrder, isFalse);
    });
  });

  group('motion', () {
    testWidgets('the bar total goes "Updating…" then reads the new total', (
      tester,
    ) async {
      await pump(tester, _snapshot(_cartOf(const [_rice])));

      await emit(
        tester,
        CartSnapshot(
          cart: _cartOf([_rice.withQuantity(2)]),
          isRestored: true,
          hasPendingChanges: true,
          revision: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.descendant(
          of: find.byType(CartCheckoutBar),
          matching: find.text('Updating…'),
        ),
        findsOneWidget,
      );

      await emit(
        tester,
        _snapshot(
          _cartOf([
            _rice.withQuantity(2),
          ], totals: const CartTotalsEntity(totalFils: 4500)),
          revision: 3,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final semantics = tester.ensureSemantics();
      expect(
        find.descendant(
          of: find.byType(CartCheckoutBar),
          matching: find.bySemanticsLabel('KD 4.500'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a leaving line folds away; an arriving one opens in', (
      tester,
    ) async {
      await pump(tester, _snapshot(_cartOf(const [_rice, _oil])));

      await emit(tester, _snapshot(_cartOf(const [_rice]), revision: 2));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Olive oil'), findsOneWidget); // folding
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Olive oil'), findsNothing);

      await emit(tester, _snapshot(_cartOf(const [_rice, _oil]), revision: 3));
      final slot = find.byKey(const ValueKey<Object>(CartLineRef('p2')));
      await tester.pump(const Duration(milliseconds: 100));
      final opening = tester.getSize(slot).height;
      await tester.pump(const Duration(milliseconds: 400));
      expect(opening, lessThan(tester.getSize(slot).height));
      expect(find.text('Olive oil'), findsOneWidget);
    });

    testWidgets('more than four changes land at once, with no ghost', (
      tester,
    ) async {
      final lines = <CartLineEntity>[
        for (var i = 0; i < 6; i++)
          CartLineEntity(
            key: 'k$i',
            product: _product('m$i', 'Item number $i'),
            quantity: 1,
            unitPriceFils: 1000,
            lineTotalFils: 1000,
          ),
      ];
      phone(tester, height: 1600);
      await pump(tester, _snapshot(_cartOf(lines)));
      expect(find.byType(CartLineTile), findsNWidgets(6));

      await emit(tester, _snapshot(_cartOf([lines.first]), revision: 2));
      for (var i = 1; i < 6; i++) {
        expect(find.text('Item number $i'), findsNothing);
      }
      await tester.pump();
      expect(find.byType(CartLineTile), findsOneWidget);
    });

    testWidgets('a coupon landing fills the ticket with a bump', (
      tester,
    ) async {
      phone(tester, height: 1600);
      await pump(tester, _snapshot(_cartOf(const [_rice])));
      Finder ticket() => find.descendant(
        of: find.byType(CartCouponRow),
        matching: find.byType(ScaleTransition),
      );
      expect(tester.widget<ScaleTransition>(ticket()).scale.value, 1);

      await emit(
        tester,
        _snapshot(
          CartEntity(
            itemCount: 1,
            lines: const [_rice],
            coupon: const CartCouponEntity(code: 'SAVE5', discountFils: 500),
          ),
          revision: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('SAVE5 applied'), findsOneWidget);
      expect(find.byIcon(Icons.confirmation_number_rounded), findsOneWidget);
      expect(
        tester.widget<ScaleTransition>(ticket()).scale.value,
        greaterThan(1),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<ScaleTransition>(ticket()).scale.value, 1);
    });

    testWidgets('the sync banner folds away, then builds nothing', (
      tester,
    ) async {
      await pump(tester, _snapshot(_cartOf(const [_rice])));
      const unsynced = "Some changes haven't reached the server yet.";
      expect(find.text(unsynced), findsNothing);

      await emit(
        tester,
        CartSnapshot(
          cart: _cartOf(const [_rice]),
          isRestored: true,
          isUnsynced: true,
          revision: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(unsynced), findsOneWidget);

      await emit(tester, _snapshot(_cartOf(const [_rice]), revision: 3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(unsynced), findsOneWidget); // still folding
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(unsynced), findsNothing);
    });

    testWidgets('reduced motion: the same end state at once, nothing running', (
      tester,
    ) async {
      await pump(
        tester,
        _snapshot(_cartOf(const [_rice, _oil])),
        reduceMotion: true,
      );
      expect(tester.hasRunningAnimations, isFalse);

      await emit(tester, _snapshot(_cartOf(const [_rice]), revision: 2));
      await tester.pump();
      expect(find.text('Olive oil'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);

      await emit(
        tester,
        _snapshot(_cartOf([_rice.withQuantity(2)]), revision: 3),
      );
      expect(tester.hasRunningAnimations, isFalse);
      // The line's stepper (the bar's basket badge counts 2 as well).
      expect(
        find.descendant(
          of: find.byType(CartLineTile),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });
  });
}
