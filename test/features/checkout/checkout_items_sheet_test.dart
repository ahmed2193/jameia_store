// The "Total N pcs" items sheet (G2): lazy under its finite max height
// (CT-S1), hugging a short basket (CT-S2), rows of different heights that
// never overflow on a small phone at 1.3× text, and the old page list's
// guarantees moved into the sheet — a re-price rebuilds only the changed
// row, a line that shifts up keeps its row, a gift added by a re-price
// appears. Issue rows carry their tag and a blocking line can be removed.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_gift_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_items_list.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_items_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_line_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_line_tile.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_order_summary.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_sheet_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

const CartLineEntity _rice = CartLineEntity(
  key: 'l1',
  product: testProduct,
  quantity: 2,
  unitPriceFils: 600,
  lineTotalFils: 1200,
);
const CartLineEntity _oil = CartLineEntity(
  key: 'l2',
  product: otherProduct,
  quantity: 1,
  unitPriceFils: 900,
  lineTotalFils: 900,
);
const CatalogProductEntity _dates = CatalogProductEntity(
  id: 'p3',
  slug: 'dates',
  name: 'Dates',
  priceFils: 700,
  stock: 5,
);
const CartOfferLineEntity _gift = CartOfferLineEntity(
  key: 'g1',
  offerId: 'o1',
  offerName: 'Buy 2 get 1',
  quantity: 1,
  product: _dates,
);

CartSnapshot _snapshot(
  List<CartLineEntity> lines, {
  List<CartOfferLineEntity> gifts = const <CartOfferLineEntity>[],
}) {
  final subtotal = lines.fold<int>(0, (sum, line) => sum + line.lineTotalFils);
  return CartSnapshot(
    cart: CartEntity(
      itemCount: lines.fold<int>(0, (sum, line) => sum + line.quantity),
      lines: lines,
      offerLines: gifts,
      totals: CartTotalsEntity(subtotalFils: subtotal, totalFils: subtotal),
    ),
    isRestored: true,
  );
}

/// [count] distinct one-piece lines.
List<CartLineEntity> _manyLines(int count) => <CartLineEntity>[
  for (var i = 0; i < count; i++)
    CartLineEntity(
      key: 'k$i',
      product: CatalogProductEntity(
        id: 'many$i',
        slug: 'many-$i',
        name: 'Product $i',
        priceFils: 500,
        stock: 9,
      ),
      quantity: 1,
      unitPriceFils: 500,
      lineTotalFils: 500,
    ),
];

void main() {
  late FakeCartRepository cartRepository;
  late CheckoutCubit checkoutCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository();
    checkoutCubit = buildCheckoutCubit(FakeCheckoutRepository());
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await checkoutCubit.close();
    await cartRepository.dispose();
  });

  /// The order summary over a cart that opens on [snapshot] (rice × 2 +
  /// oil × 1 by default), with its items sheet open.
  Future<void> openSheet(
    WidgetTester tester, {
    CartSnapshot? snapshot,
    Locale locale = checkoutEn,
    Size size = const Size(480, 2400),
    double textScale = 1,
  }) async {
    cartRepository.snapshot =
        snapshot ?? _snapshot(const <CartLineEntity>[_rice, _oil]);
    // Built outside the test's fake clock, as a setUp would build it.
    final cart = (await tester.runAsync(
      () async => buildCartCubit(cartRepository),
    ))!;
    addTearDown(cart.close);
    final ui = await pumpCheckoutSection(
      tester,
      const CheckoutOrderSummary(),
      cart: cart,
      checkout: checkoutCubit,
      locale: locale,
      size: size,
      textScale: textScale,
    );
    ui.requestItems();
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutItemsSheet), findsOneWidget);
  }

  /// Pushes a cart snapshot the way the repository stream delivers it.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(CheckoutItemsSheet), matching: matching);

  testWidgets('lists every line: name, "2x KD 0.600" and the line total', (
    tester,
  ) async {
    await openSheet(tester);

    expect(inSheet(find.text('Total 3 pcs')), findsOneWidget);
    expect(inSheet(find.byType(CheckoutLineRow)), findsNWidgets(2));
    expect(inSheet(find.text('Basmati rice')), findsOneWidget);
    expect(inSheet(find.text('Olive oil')), findsOneWidget);
    expect(inSheet(find.text('2x')), findsOneWidget);
    expect(inSheet(find.text('KD 0.600')), findsOneWidget);
    expect(inSheet(find.text('KD 1.200')), findsOneWidget);
    // Oil: one piece at KD 0.900 — its unit price and its total.
    expect(inSheet(find.text('KD 0.900')), findsNWidgets(2));
    // Nothing flagged, nothing to remove.
    expect(inSheet(find.text('Remove')), findsNothing);
  });

  testWidgets('CT-S1: the sheet builds only what it shows', (tester) async {
    await openSheet(
      tester,
      snapshot: _snapshot(_manyLines(60)),
      size: const Size(360, 800),
    );

    expect(
      find.byType(CheckoutLineRow, skipOffstage: false).evaluate().length,
      lessThanOrEqualTo(20),
    );
    // It still scrolls to the end.
    final list = find.descendant(
      of: find.byType(CheckoutItemsList),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(list).position.maxScrollExtent,
      greaterThan(0),
    );
  });

  testWidgets('CT-S2: a short list hugs its rows', (tester) async {
    await openSheet(tester, size: const Size(360, 800));

    final frame = tester.getSize(find.byType(CheckoutSheetFrame));
    expect(
      frame.height,
      lessThan(800 * CheckoutSheetFrame.defaultMaxHeightFactor),
    );
    final list = find.descendant(
      of: find.byType(CheckoutItemsList),
      matching: find.byType(Scrollable),
    );
    expect(tester.state<ScrollableState>(list).position.maxScrollExtent, 0);
  });

  for (final locale in const <Locale>[checkoutEn, checkoutAr]) {
    testWidgets('rows of different heights fit a 360 × 800 phone at 1.3× '
        '(${locale.languageCode})', (tester) async {
      if (locale == checkoutAr) Intl.defaultLocale = 'ar';
      const plain = CartLineEntity(
        key: 'a',
        product: CatalogProductEntity(id: 'a', slug: 'a', name: 'Salt'),
        quantity: 1,
        unitPriceFils: 150,
        lineTotalFils: 150,
      );
      const deal = CartLineEntity(
        key: 'b',
        product: CatalogProductEntity(
          id: 'b',
          slug: 'b',
          name:
              'Almarai full cream fresh milk with added vitamins, family '
              'size bottle',
        ),
        quantity: 12,
        unitPriceFils: 11950,
        compareAtFils: 13500,
        lineTotalFils: 143400,
        variantName: '2 litre',
      );
      const gone = CartLineEntity(
        key: 'c',
        product: CatalogProductEntity(
          id: 'c',
          slug: 'c',
          name: 'Fresh strawberries imported 250 g punnet',
        ),
        quantity: 3,
        unitPriceFils: 1250,
        compareAtFils: 1500,
        lineTotalFils: 3750,
        issue: CartLineIssue.outOfStock,
      );
      const cut = CartLineEntity(
        key: 'd',
        product: CatalogProductEntity(id: 'd', slug: 'd', name: 'Eggs 30'),
        quantity: 2,
        unitPriceFils: 2100,
        lineTotalFils: 4200,
        issue: CartLineIssue.quantityReduced,
      );
      await openSheet(
        tester,
        snapshot: _snapshot(
          const <CartLineEntity>[plain, deal, gone, cut],
          gifts: const <CartOfferLineEntity>[_gift],
        ),
        locale: locale,
        size: const Size(360, 800),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      final plainRow = tester.getSize(
        find.byKey(CheckoutLineTile.keyFor(plain.ref)),
      );
      final goneRow = tester.getSize(
        find.byKey(CheckoutLineTile.keyFor(gone.ref)),
      );
      // A tag, a two-line name and "Remove" make a taller row.
      expect(goneRow.height, greaterThan(plainRow.height));

      // Scroll through every row; nothing overflows on the way.
      final list = find.descendant(
        of: find.byType(CheckoutItemsList),
        matching: find.byType(Scrollable),
      );
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CheckoutGiftRow), findsOneWidget);
    });
  }

  testWidgets('a re-price rebuilds only the row whose line changed', (
    tester,
  ) async {
    await openSheet(tester);
    final rows = RebuildProbe<CheckoutLineRow, String>(
      (row) => row.line.product.id,
    )..start();
    addTearDown(rows.stop);

    // A fresh list from the server: rice re-priced, oil an equal new copy.
    await emit(
      tester,
      _snapshot(<CartLineEntity>[
        _rice.withQuantity(3),
        CartLineEntity(
          key: _oil.key,
          product: _oil.product,
          quantity: _oil.quantity,
          unitPriceFils: _oil.unitPriceFils,
          lineTotalFils: _oil.lineTotalFils,
        ),
      ]),
    );

    expect(rows.of(testProduct.id), 1);
    expect(rows.of(otherProduct.id), 0);
    expect(inSheet(find.text('KD 1.800')), findsOneWidget);
  });

  testWidgets('a line that shifts up keeps its row when the one above goes', (
    tester,
  ) async {
    await openSheet(tester);
    final oilTile = find.byKey(CheckoutLineTile.keyFor(_oil.ref));
    final oilRow = find.descendant(
      of: oilTile,
      matching: find.byType(CheckoutLineRow),
    );
    final tileBefore = tester.element(oilTile);
    final rowBefore = tester.element(oilRow);

    // Rice goes: oil moves from the second row to the first.
    await emit(tester, _snapshot(const <CartLineEntity>[_oil]));

    expect(inSheet(find.byType(CheckoutLineRow)), findsOneWidget);
    expect(find.byKey(CheckoutLineTile.keyFor(_rice.ref)), findsNothing);
    expect(identical(tester.element(oilTile), tileBefore), isTrue);
    expect(identical(tester.element(oilRow), rowBefore), isTrue);
  });

  testWidgets('a gift added by a re-price while the sheet is open appears', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.byType(CheckoutGiftRow), findsNothing);

    await emit(
      tester,
      _snapshot(
        const <CartLineEntity>[_rice, _oil],
        gifts: const <CartOfferLineEntity>[_gift],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CheckoutGiftRow.keyFor(_gift.key)), findsOneWidget);
    expect(inSheet(find.text('Dates')), findsOneWidget);
    expect(inSheet(find.text('Buy 2 get 1')), findsOneWidget);
    expect(inSheet(find.text('Free')), findsOneWidget);
    // The gift's own price, struck.
    expect(inSheet(find.text('KD 0.700')), findsOneWidget);
    expect(inSheet(find.text('Total 4 pcs')), findsOneWidget);
  });

  testWidgets('issue rows show their tag; "Remove" takes a blocking line out', (
    tester,
  ) async {
    await openSheet(
      tester,
      snapshot: _snapshot(<CartLineEntity>[
        CartLineEntity(
          key: _rice.key,
          product: _rice.product,
          quantity: _rice.quantity,
          unitPriceFils: _rice.unitPriceFils,
          lineTotalFils: _rice.lineTotalFils,
          issue: CartLineIssue.outOfStock,
        ),
        CartLineEntity(
          key: _oil.key,
          product: _oil.product,
          quantity: _oil.quantity,
          unitPriceFils: _oil.unitPriceFils,
          lineTotalFils: _oil.lineTotalFils,
          issue: CartLineIssue.quantityReduced,
        ),
      ]),
    );

    expect(inSheet(find.text('Out of stock')), findsOneWidget);
    expect(
      inSheet(find.text("Quantity reduced to what's in stock")),
      findsOneWidget,
    );
    // Only the line that blocks the order can be removed from here.
    expect(inSheet(find.text('Remove')), findsOneWidget);

    await tester.tap(inSheet(find.text('Remove')));
    await tester.pump();

    expect(cartRepository.calls, contains('remove:${_rice.ref}'));
  });

  testWidgets('a deal line shows its "% off" tag and the struck was-price', (
    tester,
  ) async {
    await openSheet(
      tester,
      snapshot: _snapshot(const <CartLineEntity>[
        CartLineEntity(
          key: 'l1',
          product: testProduct,
          quantity: 2,
          unitPriceFils: 600,
          compareAtFils: 800,
          lineTotalFils: 1200,
        ),
      ]),
    );

    // (800 − 600) / 800 = 25%.
    expect(inSheet(find.text('25% off')), findsOneWidget);
    expect(inSheet(find.text('KD 0.800')), findsOneWidget);
    expect(inSheet(find.text('KD 1.200')), findsOneWidget);
  });

  testWidgets('the sheet closes itself when the last line goes', (
    tester,
  ) async {
    await openSheet(tester);

    await emit(
      tester,
      const CartSnapshot(cart: CartEntity.empty, isRestored: true),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutItemsSheet), findsNothing);
  });

  testWidgets('Arabic: the title counts the pieces, the rows run right to '
      'left and money stays left to right', (tester) async {
    Intl.defaultLocale = 'ar';
    await openSheet(
      tester,
      snapshot: _snapshot(const <CartLineEntity>[_rice]),
      locale: checkoutAr,
    );

    expect(inSheet(find.text('المجموع قطعتان')), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(CheckoutLineRow))),
      TextDirection.rtl,
    );
    expect(inSheet(find.text('د.ك 1.200')), findsOneWidget);
  });
}
