// What a change on the checkout page rebuilds (perf spec R5 / R10 / R4):
// a notes keystroke only the notes field, a re-price only the rows whose line
// changed, a line that goes leaves the other rows in place, the bar's total
// rolls in place instead of being re-created, and once the order is placed
// the cart emptying under the outgoing page moves nothing.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/motion/rolling_number.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_state.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_address_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_items_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_line_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_line_tile.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_payment_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_order_bar.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_summary.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_timing_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late CheckoutCubit checkoutCubit;
  late AuthSessionCubit session;
  late AddressBookCubit addressBook;

  const rice = CartLineEntity(
    key: 'l1',
    product: testProduct,
    quantity: 2,
    unitPriceFils: 600,
    lineTotalFils: 1200,
  );
  const oil = CartLineEntity(
    key: 'l2',
    product: otherProduct,
    quantity: 1,
    unitPriceFils: 900,
    lineTotalFils: 900,
  );

  CartSnapshot snapshot({
    required List<CartLineEntity> lines,
    required int totalFils,
  }) => CartSnapshot(
    cart: CartEntity(
      itemCount: 3,
      lines: lines,
      totals: CartTotalsEntity(
        subtotalFils: totalFils - 500,
        deliveryFeeFils: 500,
        baseDeliveryFeeFils: 500,
        totalFils: totalFils,
      ),
    ),
    isRestored: true,
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = snapshot(lines: const [rice, oil], totalFils: 2600);
    cartCubit = buildCartCubit(cartRepository);
    checkoutCubit = buildCheckoutCubit(FakeCheckoutRepository());
    session = buildSessionCubit();
    addressBook = buildAddressBookCubit();
  });

  tearDown(() async {
    await checkoutCubit.close();
    await cartCubit.close();
    await session.close();
    await addressBook.close();
    await cartRepository.dispose();
  });

  /// A priced checkout (address a1 selected), tall enough that every section
  /// is built.
  Future<void> pump(WidgetTester tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pumpCheckoutBody(
      tester,
      cart: cartCubit,
      checkout: checkoutCubit,
      session: session,
      addressBook: addressBook,
    );
  }

  Finder inBar(Finder matching) => find.descendant(
    of: find.byType(CheckoutPlaceOrderBar),
    matching: matching,
  );

  /// Pushes a cart snapshot the way the repository stream delivers it.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  testWidgets('T4: a notes keystroke rebuilds only the notes field', (
    tester,
  ) async {
    await pump(tester);
    final probe = RebuildProbe<Widget, Type>((widget) => widget.runtimeType)
      ..start();
    addTearDown(probe.stop);

    await tester.enterText(find.byType(TextField), 'ring the bell');
    await tester.pump();

    expect(checkoutCubit.state.draft.notes, 'ring the bell');
    // The probe is live: the field itself did rebuild.
    expect(probe.of(TextField), greaterThan(0));
    for (final section in const <Type>[
      CheckoutBody,
      CheckoutAddressSection,
      CheckoutTimingSection,
      CheckoutPaymentSection,
      CheckoutItemsSection,
      CheckoutLineRow,
      CheckoutSummary,
      CheckoutPlaceOrderBar,
    ]) {
      expect(probe.of(section), 0, reason: '$section rebuilt on a keystroke');
    }
  });

  testWidgets('a re-price rebuilds only the row whose line changed', (
    tester,
  ) async {
    await pump(tester);
    final rows = RebuildProbe<CheckoutLineRow, String>(
      (row) => row.line.product.id,
    )..start();
    addTearDown(rows.stop);

    // A fresh list from the server: rice re-priced, oil an equal new copy.
    await emit(
      tester,
      snapshot(
        lines: [
          rice.withQuantity(3),
          CartLineEntity(
            key: oil.key,
            product: oil.product,
            quantity: oil.quantity,
            unitPriceFils: oil.unitPriceFils,
            lineTotalFils: oil.lineTotalFils,
          ),
        ],
        totalFils: 3200,
      ),
    );

    expect(rows.of(testProduct.id), 1);
    expect(rows.of(otherProduct.id), 0);
    expect(find.text('KD 1.800'), findsOneWidget);
  });

  testWidgets('the bar total rolls in place on a re-quote', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    final roller = find.descendant(
      of: find.byType(CheckoutPlaceOrderBar),
      matching: find.byType(RollingNumber),
    );
    final before = tester.element(roller);

    await emit(tester, snapshot(lines: const [rice, oil], totalFils: 2900));
    await tester.pumpAndSettle();

    expect(identical(tester.element(roller), before), isTrue);
    expect(
      find.descendant(
        of: find.byType(CheckoutPlaceOrderBar),
        matching: find.bySemanticsLabel('KD 2.900'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a line that shifts up keeps its row when the one above goes', (
    tester,
  ) async {
    await pump(tester);
    final oilTile = find.byKey(CheckoutLineTile.keyFor(oil.ref));
    final oilRow = find.descendant(
      of: oilTile,
      matching: find.byType(CheckoutLineRow),
    );
    final tileBefore = tester.element(oilTile);
    final rowBefore = tester.element(oilRow);

    // Rice goes: oil moves from the second row to the first.
    await emit(tester, snapshot(lines: const [oil], totalFils: 1400));

    expect(find.byType(CheckoutLineRow), findsOneWidget);
    expect(find.byKey(CheckoutLineTile.keyFor(rice.ref)), findsNothing);
    expect(identical(tester.element(oilTile), tileBefore), isTrue);
    expect(identical(tester.element(oilRow), rowBefore), isTrue);
  });

  testWidgets('placed: the cart emptying under the page moves nothing', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(checkoutCubit.placeOrder);
    // The check pops on the button; let it land.
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.status, CheckoutStatus.placed);

    // CartCubit.onOrderPlaced empties the cart while the page is still on
    // screen under the tracking page's entrance.
    await emit(
      tester,
      const CartSnapshot(cart: CartEntity.empty, isRestored: true),
    );

    // Nothing ticks: no roll, no resize, no fold behind the transition.
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 1));
    // The bar still shows the amount just placed (KD 2.600): its digits never
    // rolled down to 0.000.
    final six = inBar(find.text('6'));
    expect(six, findsOneWidget);
    final glyphFade = find
        .ancestor(of: six, matching: find.byType(FadeTransition))
        .first;
    expect(tester.widget<FadeTransition>(glyphFade).opacity.value, 1);
  });
}
