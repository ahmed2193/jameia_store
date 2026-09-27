// The checkout rail, "Deals you might have missed" (G2): decided before the
// page's first paint and never changing height afterwards (replaces CT-RL1 /
// RL2). Ready → the heading and the 130 dp shelf cards, a third one peeking
// in at 360 dp; empty, failing or later than `settleLimit` → no rail at all,
// and a late reply never brings it in. "+" adds to the app-global cart.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/widgets/catalog_product_card.dart';
import 'package:hero_mart/src/core/widgets/shelf_add_button.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_rail_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_rail_state.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_rail_section.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_rail_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';
import 'fake_checkout_repository.dart';

/// On-sale, in-stock products, as the rail's use case keeps them.
const List<CatalogProductEntity> _deals = <CatalogProductEntity>[
  CatalogProductEntity(
    id: 'coriander',
    slug: 'coriander',
    name: 'Coriander',
    priceFils: 100,
    compareAtFils: 150,
    stock: 9,
  ),
  CatalogProductEntity(
    id: 'cheese',
    slug: 'cheese',
    name: 'Cheese puff',
    priceFils: 1400,
    compareAtFils: 2000,
    stock: 4,
  ),
  CatalogProductEntity(
    id: 'parsley',
    slug: 'parsley',
    name: 'Chopped parsley',
    priceFils: 1570,
    compareAtFils: 2250,
    stock: 1,
  ),
  CatalogProductEntity(
    id: 'flour',
    slug: 'flour',
    name: 'Flour',
    priceFils: 630,
    compareAtFils: 1000,
    stock: 7,
  ),
];

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late CheckoutCubit checkoutCubit;
  late FakeCheckoutCatalogRepository catalog;
  late CheckoutRailCubit rail;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = const CartSnapshot(isRestored: true);
    cartCubit = buildCartCubit(cartRepository);
    checkoutCubit = buildCheckoutCubit(FakeCheckoutRepository());
    catalog = FakeCheckoutCatalogRepository(products: _deals);
    rail = buildRailCubit(catalog);
  });

  tearDown(() async {
    await rail.close();
    await checkoutCubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  /// Settles the rail the way the page does before its content shows.
  Future<void> settle(WidgetTester tester) =>
      tester.runAsync(() => rail.load(excludeProductIds: const <String>{}));

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(480, 2400),
    Locale locale = checkoutEn,
  }) => pumpCheckoutSection(
    tester,
    const CheckoutRailSection(),
    cart: cartCubit,
    checkout: checkoutCubit,
    rail: rail,
    size: size,
    locale: locale,
  );

  /// The section, found even when it takes no room (a zero-size sliver
  /// child counts as offstage).
  final section = find.byType(CheckoutRailSection, skipOffstage: false);

  Finder tile(String id) => find.byWidgetPredicate(
    (widget) => widget is CheckoutRailTile && widget.product.id == id,
  );

  testWidgets('ready: the heading, then the cards; at 360 dp a third one '
      'peeks in', (tester) async {
    await settle(tester);
    await pump(tester, size: const Size(360, 800));

    expect(find.text('Deals you might have missed'), findsOneWidget);
    expect(find.text('On sale now and in stock'), findsOneWidget);
    expect(find.byType(CatalogProductCard), findsWidgets);

    // 12 dp gutter, then 130 dp cards 8 dp apart.
    final first = tester.getRect(tile('coriander'));
    expect(first.left, 12);
    expect(first.width, CatalogProductCard.defaultWidth);
    final third = tester.getRect(tile('parsley'));
    expect(third.left, lessThan(360));
    expect(third.right, greaterThan(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rail is as tall as a card cell, from the first frame', (
    tester,
  ) async {
    await settle(tester);
    await pump(tester);

    final list = find.descendant(
      of: find.byType(CheckoutRailSection),
      matching: find.byType(ListView),
    );
    expect(
      tester.getSize(list).height,
      CatalogProductCard.cellHeight(tester.element(list)),
    );
  });

  testWidgets('"+" adds to the cart; the rail keeps its height', (
    tester,
  ) async {
    await settle(tester);
    await pump(tester);
    final before = tester.getSize(find.byType(CheckoutRailSection));

    await tester.tap(
      find.descendant(
        of: tile('cheese'),
        matching: find.byType(ShelfAddButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(cartRepository.calls, contains('adjust:cheese::1'));
    expect(tester.getSize(find.byType(CheckoutRailSection)), before);
  });

  testWidgets('no products: no rail', (tester) async {
    catalog.products = const <CatalogProductEntity>[];
    await settle(tester);
    expect(rail.state.status, CheckoutRailStatus.hidden);
    await pump(tester);

    expect(find.byType(CheckoutRailTile), findsNothing);
    expect(find.text('Deals you might have missed'), findsNothing);
    expect(tester.getSize(section).height, 0);
  });

  testWidgets('a failing read: no rail', (tester) async {
    catalog.railFailure = const NetworkFailure();
    await settle(tester);
    expect(rail.state.status, CheckoutRailStatus.hidden);
    await pump(tester);

    expect(find.byType(CheckoutRailTile), findsNothing);
    expect(tester.getSize(section).height, 0);
  });

  testWidgets('a reply later than settleLimit never brings the rail in', (
    tester,
  ) async {
    final gate = Completer<void>();
    catalog.railGate = gate;
    // Started on the test clock; its settle timer runs on it too.
    unawaited(rail.load(excludeProductIds: const <String>{}));
    await pump(tester);
    expect(tester.getSize(section).height, 0);

    await tester.pump(CheckoutRailCubit.settleLimit);
    expect(rail.state.status, CheckoutRailStatus.hidden);

    // The products arrive after all: too late.
    gate.complete();
    await tester.pumpAndSettle();

    expect(rail.state.status, CheckoutRailStatus.hidden);
    expect(find.byType(CheckoutRailTile), findsNothing);
    expect(tester.getSize(section).height, 0);
  });

  testWidgets('Arabic at 360 × 800 @ 1.3×: the cards run from the right, '
      'nothing overflows', (tester) async {
    await settle(tester);
    await pumpCheckoutSection(
      tester,
      const CheckoutRailSection(),
      cart: cartCubit,
      checkout: checkoutCubit,
      rail: rail,
      locale: checkoutAr,
      size: const Size(360, 800),
      textScale: 1.3,
    );

    expect(find.text('عروض ربما فاتتك'), findsOneWidget);
    final first = tester.getRect(tile('coriander'));
    expect(first.right, 360 - 12);
    expect(tester.takeException(), isNull);
  });
}
