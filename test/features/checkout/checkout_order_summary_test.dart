// The order summary (G2): the strip of line pictures with "N pcs ›", the
// warn badge on a flagged line, the "items unavailable" banner, and every
// way into the "Total N pcs" sheet (a tap, the banner, a blocked "Place
// order" asking through the UI controller). Checkout thumbs decode at the
// cart row's 56 dp (CT-I1).
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/responsive/app_size.dart';
import 'package:jameia_mart/src/core/widgets/jameia_image.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_issue_banner.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_items_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_order_summary.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumb_slot.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumb_tile.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumbs_strip.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_ui_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

CartLineEntity _flag(CartLineEntity line, CartLineIssue issue) =>
    CartLineEntity(
      key: line.key,
      product: line.product,
      quantity: line.quantity,
      unitPriceFils: line.unitPriceFils,
      lineTotalFils: line.lineTotalFils,
      issue: issue,
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
    await checkoutCubit.close();
    await cartRepository.dispose();
  });

  /// The summary over a cart that opens on [snapshot] (rice × 2 + oil × 1
  /// by default).
  Future<CheckoutUiController> pump(
    WidgetTester tester, {
    CartSnapshot? snapshot,
    Locale locale = checkoutEn,
  }) async {
    cartRepository.snapshot =
        snapshot ?? _snapshot(const <CartLineEntity>[_rice, _oil]);
    // Built outside the test's fake clock, as a setUp would build it.
    final cart = (await tester.runAsync(
      () async => buildCartCubit(cartRepository),
    ))!;
    addTearDown(cart.close);
    return pumpCheckoutSection(
      tester,
      const CheckoutOrderSummary(),
      cart: cart,
      checkout: checkoutCubit,
      locale: locale,
    );
  }

  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  Finder inStrip(Finder matching) =>
      find.descendant(of: find.byType(CheckoutThumbsStrip), matching: matching);

  testWidgets('the strip shows each line and "3 pcs" for rice × 2 + oil × 1', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('3 pcs'), findsOneWidget);
    expect(inStrip(find.byType(CheckoutThumbTile)), findsNWidgets(2));
    expect(inStrip(find.text('2x')), findsOneWidget);
    expect(inStrip(find.text('1x')), findsOneWidget);
    // Nothing flagged: no badge, no banner.
    expect(find.byIcon(Icons.priority_high_rounded), findsNothing);
    expect(find.textContaining('unavailable'), findsNothing);
    // Fixed places: never more than the strip holds.
    expect(
      find.byType(CheckoutThumbSlot).evaluate().length,
      lessThanOrEqualTo(5),
    );
  });

  testWidgets('a blocking line gets a warn badge and the banner, which opens '
      'the items sheet', (tester) async {
    await pump(
      tester,
      snapshot: _snapshot(<CartLineEntity>[
        _flag(_rice, CartLineIssue.outOfStock),
        _oil,
      ]),
    );

    expect(inStrip(find.byIcon(Icons.priority_high_rounded)), findsOneWidget);
    expect(find.textContaining('1 item unavailable'), findsOneWidget);

    await tester.tap(find.byType(CheckoutIssueBanner));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutItemsSheet), findsOneWidget);
    expect(find.text('Total 3 pcs'), findsOneWidget);
  });

  testWidgets('a quantity the server cut back is badged, not "unavailable"', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot: _snapshot(<CartLineEntity>[
        _rice,
        _flag(_oil, CartLineIssue.quantityReduced),
      ]),
    );

    expect(inStrip(find.byIcon(Icons.priority_high_rounded)), findsOneWidget);
    expect(find.textContaining('unavailable'), findsNothing);
  });

  testWidgets('the banner folds in when a line becomes unavailable', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('unavailable'), findsNothing);

    await emit(
      tester,
      _snapshot(<CartLineEntity>[
        _flag(_rice, CartLineIssue.unavailable),
        _flag(_oil, CartLineIssue.outOfStock),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('2 items unavailable'), findsOneWidget);
  });

  testWidgets('a tap on the strip opens the items sheet', (tester) async {
    await pump(tester);

    await tester.tap(find.text('3 pcs'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutItemsSheet), findsOneWidget);
  });

  testWidgets('ui.requestItems() opens the items sheet, never twice', (
    tester,
  ) async {
    final ui = await pump(tester);

    ui.requestItems();
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutItemsSheet), findsOneWidget);

    // A second request while it is up stacks nothing.
    ui.requestItems();
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutItemsSheet), findsOneWidget);
  });

  testWidgets('CT-I1: strip and sheet thumbs decode at the cart row size', (
    tester,
  ) async {
    final ui = await pump(tester);

    void expectAll56(Finder images) {
      expect(images, findsWidgets);
      for (final image in tester.widgetList<JameiaImage>(images)) {
        expect(image.width, AppSize.s56);
        expect(image.height, AppSize.s56);
      }
    }

    expectAll56(inStrip(find.byType(JameiaImage)));

    ui.requestItems();
    await tester.pumpAndSettle();
    expectAll56(
      find.descendant(
        of: find.byType(CheckoutItemsSheet),
        matching: find.byType(JameiaImage),
      ),
    );
  });

  testWidgets('a new line pops into a free slot; the count follows', (
    tester,
  ) async {
    await pump(tester);
    // The first build is static.
    expect(tester.hasRunningAnimations, isFalse);

    await emit(
      tester,
      _snapshot(const <CartLineEntity>[
        _rice,
        _oil,
        CartLineEntity(
          key: 'l3',
          product: _dates,
          quantity: 1,
          unitPriceFils: 700,
          lineTotalFils: 700,
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 16));

    final popping = tester
        .widgetList<ScaleTransition>(inStrip(find.byType(ScaleTransition)))
        .where((scale) => scale.scale.value < 1);
    expect(popping, isNotEmpty);

    await tester.pumpAndSettle();
    expect(inStrip(find.byType(CheckoutThumbTile)), findsNWidgets(3));
    expect(find.text('4 pcs'), findsOneWidget);
  });

  testWidgets('free gifts count in the pieces and show a gift disc', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot: _snapshot(
        const <CartLineEntity>[_rice, _oil],
        gifts: const <CartOfferLineEntity>[
          CartOfferLineEntity(
            key: 'g1',
            offerId: 'o1',
            offerName: 'Buy 2 get 1',
            quantity: 1,
            product: _dates,
          ),
        ],
      ),
    );

    expect(find.text('4 pcs'), findsOneWidget);
    expect(inStrip(find.byIcon(Icons.card_giftcard_rounded)), findsOneWidget);
  });

  testWidgets('Arabic: the title and the pieces, right to left', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot: _snapshot(const <CartLineEntity>[_oil]),
      locale: checkoutAr,
    );

    expect(find.text('ملخص الطلب'), findsOneWidget);
    expect(find.text('قطعة واحدة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(CheckoutThumbsStrip))),
      TextDirection.rtl,
    );
  });
}
