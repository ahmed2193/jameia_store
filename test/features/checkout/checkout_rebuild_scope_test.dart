// What a change on the checkout page rebuilds (perf spec R5 / R10 / R4):
// typing a note rebuilds no section (the note lives in its sheet) and saving
// it rebuilds only the note row, the bar's total rolls in place instead of
// being re-created, and once the order is placed the cart emptying under the
// outgoing page moves nothing — no hint, no rotating line, no frame.
//
// The item rows now live in the items sheet: their scopes (a re-price
// rebuilds one row, a row that shifts up keeps its element) are pinned in
// checkout_items_sheet_test.dart.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/motion/rolling_number.dart';
import 'package:jameia_mart/src/core/motion/rotating_line.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cart_facts_of.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_state.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_address_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_fact_text.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_line.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_total.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_card.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_hint_bubble.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_info_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_note_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_note_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_options_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_order_summary.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_payment_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_button.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_order_bar.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_rail_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_receipt.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_hint.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_sheet_frame.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumbs_strip.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_where_when_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

/// Every section of the page and every part of the bar that a note must
/// never wake.
const List<Type> _sections = <Type>[
  CheckoutBody,
  CheckoutWhereWhenBlock,
  CheckoutAddressSection,
  CheckoutEtaRow,
  CheckoutEtaCard,
  CheckoutRailSection,
  CheckoutOrderSummary,
  CheckoutThumbsStrip,
  CheckoutSavingsSection,
  CheckoutReceipt,
  CheckoutPaymentSection,
  CheckoutOptionsSection,
  CheckoutInfoSection,
  CheckoutPlaceOrderBar,
  CheckoutBarTotal,
  CheckoutBarLine,
  CheckoutPlaceButton,
  RotatingLine,
  CheckoutSavingsHint,
];

/// The parts of the page that read whether a sheet covers it (the fact
/// line pauses under one, the hint waits for the route to settle), so a
/// sheet closing wakes them once.
const Set<Type> _readsRoute = <Type>{
  CheckoutBarLine,
  RotatingLine,
  CheckoutSavingsHint,
};

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

  /// Rice on sale: 0.300 off each of its 2 pieces (the hint's line).
  const riceOnSale = CartLineEntity(
    key: 'l1',
    product: testProduct,
    quantity: 2,
    unitPriceFils: 600,
    compareAtFils: 900,
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
    List<CartLineEntity> lines = const [rice, oil],
    required int totalFils,
    CartCouponEntity? coupon,
    int couponDiscountFils = 0,
  }) => CartSnapshot(
    cart: CartEntity(
      itemCount: 3,
      lines: lines,
      coupon: coupon,
      totals: CartTotalsEntity(
        subtotalFils: totalFils - 500 + couponDiscountFils,
        couponDiscountFils: couponDiscountFils,
        discountFils: couponDiscountFils,
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
    cartRepository = FakeCartRepository()..snapshot = snapshot(totalFils: 2600);
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

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(CheckoutSheetFrame), matching: matching);

  /// Pushes a cart snapshot the way the repository stream delivers it.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  testWidgets('T4: a note keystroke rebuilds no section; Save only the row', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(CheckoutNoteRow));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutNoteSheet), findsOneWidget);

    final probe = RebuildProbe<Widget, Type>((widget) => widget.runtimeType)
      ..start();
    addTearDown(probe.stop);

    await tester.enterText(inSheet(find.byType(TextField)), 'ring the bell');
    await tester.pump();

    // Typing only edits the field: the draft waits for the sheet to close.
    expect(checkoutCubit.state.draft.notes, isEmpty);
    // The probe is live: the field's editable text did rebuild.
    expect(probe.of(EditableText), greaterThan(0));
    for (final section in <Type>[..._sections, CheckoutNoteRow]) {
      expect(probe.of(section), 0, reason: '$section rebuilt on a keystroke');
    }

    probe.reset();
    await tester.tap(inSheet(find.text('Save')));
    await tester.pumpAndSettle();

    expect(checkoutCubit.state.draft.notes, 'ring the bell');
    expect(find.byType(CheckoutNoteSheet), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CheckoutNoteRow),
        matching: find.text('ring the bell'),
      ),
      findsOneWidget,
    );
    // The saved note reaches only the row that shows it. The widgets that
    // read whether a sheet covers the page wake once as it closes; that is
    // the route, not the note.
    expect(probe.of(CheckoutNoteRow), greaterThan(0));
    for (final section in _sections.where(
      (type) => !_readsRoute.contains(type),
    )) {
      expect(probe.of(section), 0, reason: '$section rebuilt on a saved note');
    }
  });

  testWidgets('the bar total rolls in place on a re-quote', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    final roller = inBar(find.byType(RollingNumber));
    expect(roller, findsOneWidget);
    final before = tester.element(roller);

    await emit(tester, snapshot(totalFils: 2900));
    await tester.pumpAndSettle();

    expect(identical(tester.element(roller), before), isTrue);
    expect(inBar(find.bySemanticsLabel('KD 2.900')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('placed: the cart emptying under the page moves nothing', (
    tester,
  ) async {
    // Two facts take turns on the line (the savings, the coupon's) and the
    // hint points at the rice on sale.
    cartRepository.push(
      snapshot(
        lines: const [riceOnSale, oil],
        totalFils: 2600,
        coupon: const CartCouponEntity(code: 'SAVE', discountFils: 100),
        couponDiscountFils: 100,
      ),
    );
    await pump(tester);
    expect(find.byType(CheckoutHintBubble), findsOneWidget);
    expect(inBar(find.byType(RotatingLine)), findsOneWidget);
    final firstFact = tester
        .widgetList<CheckoutBarFactText>(
          inBar(find.byType(CheckoutBarFactText)),
        )
        .first
        .fact;

    await tester.runAsync(
      () => checkoutCubit.placeOrder(
        cartCubit.state.checkoutFacts(walletFils: null),
      ),
    );
    // The check pops on the button; let it land.
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.status, CheckoutStatus.placed);

    // The hint is gone and the line stands still on its first fact: no
    // dwell timer, no frame, however long the page stays.
    expect(find.byType(CheckoutHintBubble), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(
      tester.state<RotatingLineState>(find.byType(RotatingLine)).debugResting,
      isFalse,
    );
    final shown = tester
        .widgetList<CheckoutBarFactText>(
          inBar(find.byType(CheckoutBarFactText)),
        )
        .map((text) => text.fact);
    expect(shown, <Object>[firstFact]);

    // CartCubit.onOrderPlaced empties the cart while the page is still on
    // screen under the tracking page's entrance.
    await emit(
      tester,
      const CartSnapshot(cart: CartEntity.empty, isRestored: true),
    );

    // Nothing ticks: no roll, no resize, no fold behind the transition.
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byType(CheckoutHintBubble), findsNothing);
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
