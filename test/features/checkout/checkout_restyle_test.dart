// The restyled checkout (docs/design_system.md): a white page of grouped
// rows, a gliding delivery / pickup switch, checkable choice rows, slot pills
// in a sheet, flat item rows and a pinned bar whose total stays hidden until
// the server priced the destination. It reads the same in Arabic (money stays
// one left-to-right run) and fits a 360 dp phone at 1.3× text.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/delivery_slot_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/core/widgets/jameia_close_button.dart';
import 'package:jameia_mart/src/core/widgets/jameia_money_text.dart';
import 'package:jameia_mart/src/core/widgets/option_row.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_branch_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_order_bar.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_slot_chip.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_slot_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  const en = checkoutEn;
  const ar = checkoutAr;

  /// 2.100 of goods with the delivery mode's 0.500 fee already in the total.
  const totals = CartTotalsEntity(
    subtotalFils: 2100,
    deliveryFeeFils: 500,
    baseDeliveryFeeFils: 500,
    totalFils: 2600,
  );

  const free = DeliverySlotEntity(
    templateId: 't1',
    date: '2026-09-22',
    label: '10:00 – 12:00',
    remaining: 2,
    available: true,
  );
  const full = DeliverySlotEntity(
    templateId: 't2',
    date: '2026-09-22',
    label: '12:00 – 14:00',
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = const CartSnapshot(
        cart: CartEntity(
          itemCount: 3,
          totals: totals,
          lines: <CartLineEntity>[
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
          ],
        ),
        isRestored: true,
      );
    cartCubit = buildCartCubit(cartRepository);
    checkoutCubit = buildCheckoutCubit(
      FakeCheckoutRepository()
        ..days = const <DeliverySlotDayEntity>[
          DeliverySlotDayEntity(
            date: '2026-09-22',
            label: 'Tomorrow',
            slots: <DeliverySlotEntity>[free, full],
          ),
        ],
    );
    session = buildSessionCubit();
    addressBook = buildAddressBookCubit();
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await checkoutCubit.close();
    await cartCubit.close();
    await session.close();
    await addressBook.close();
    await cartRepository.dispose();
  });

  /// The checkout body in [locale], on a [size] screen at [textScale], with
  /// the OS "remove animations" flag when [reduceMotion].
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = en,
    Size size = const Size(480, 2400),
    double textScale = 1,
    bool reduceMotion = false,
  }) => pumpCheckoutBody(
    tester,
    cart: cartCubit,
    checkout: checkoutCubit,
    session: session,
    addressBook: addressBook,
    locale: locale,
    size: size,
    textScale: textScale,
    reduceMotion: reduceMotion,
  );

  Finder inBar(Finder matching) => find.descendant(
    of: find.byType(CheckoutPlaceOrderBar),
    matching: matching,
  );

  testWidgets('renders every section in English', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Deliver to'), findsOneWidget);
    // An address is chosen: "Change" instead of the prompt.
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Choose a delivery address'), findsNothing);
    expect(find.text('When'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Notes for the store'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Basmati rice'), findsOneWidget);
    expect(find.text('Olive oil'), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    expect(find.text('KD 1.200'), findsOneWidget);
    expect(find.text('Payment summary'), findsOneWidget);
    expect(find.text('Place order'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders right to left in Arabic, money as one LTR run', (
    tester,
  ) async {
    Intl.defaultLocale = 'ar';
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester, locale: ar);

    expect(
      Directionality.of(tester.element(find.byType(CheckoutBody))),
      TextDirection.rtl,
    );
    expect(find.text('ملخص الدفع'), findsOneWidget);
    final subtotal = find
        .descendant(
          of: find.byType(CheckoutSummary),
          matching: find.byType(JameiaMoneyText),
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

  for (final locale in const <Locale>[en, ar]) {
    testWidgets(
      'fits a 360 × 800 phone at 1.3× text (${locale.languageCode})',
      (tester) async {
        if (locale == ar) Intl.defaultLocale = 'ar';
        session.signedIn(
          const AuthCustomerEntity(id: 'c1', phone: '+96550000000'),
        );
        await checkoutCubit.start(defaultAddressId: 'a1');
        await pump(
          tester,
          locale: locale,
          size: const Size(360, 800),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        // Scroll through the whole page so every section is laid out.
        for (var i = 0; i < 8; i++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.byType(CheckoutSummary), findsOneWidget);
      },
    );
  }

  testWidgets('the mode switch moves the page to pickup', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);
    expect(find.text('Pick up from'), findsNothing);

    await tester.tap(find.text('Pickup'));
    await tester.pumpAndSettle();

    expect(checkoutCubit.state.draft.mode, FulfillmentMode.pickup);
    expect(find.text('Pick up from'), findsOneWidget);
    expect(find.text('Choose a branch'), findsOneWidget);
    expect(find.text('Deliver to'), findsNothing);
    // Pickup has no delivery timing: that section folded away.
    expect(find.text('When'), findsNothing);
  });

  testWidgets('choice rows are checkable; a short wallet ignores taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    // 1.000 in the wallet, 2.600 to pay.
    session.signedIn(
      const AuthCustomerEntity(
        id: 'c1',
        phone: '+96550000000',
        walletFils: 1000,
      ),
    );
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    final cod = find.widgetWithText(OptionRow, 'Cash on delivery');
    expect(
      tester.getSemantics(cod),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    final wallet = find.widgetWithText(OptionRow, 'Wallet');
    expect(
      tester.getSemantics(wallet),
      isSemantics(
        hasCheckedState: true,
        isChecked: false,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );

    await tester.tap(wallet);
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.draft.paymentMethod, OrderPaymentMethod.cod);
    semantics.dispose();
  });

  testWidgets('a full window is disabled; a free one books the slot', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSlotSheet), findsOneWidget);
    expect(find.text('Delivery windows'), findsOneWidget);
    expect(find.byType(CheckoutSlotChip), findsNWidgets(2));

    final fullChip = find.byKey(const ValueKey<String>('2026-09-22/t2'));
    expect(
      tester.getSemantics(fullChip),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasSelectedState: true,
        isSelected: false,
      ),
    );
    await tester.tap(fullChip);
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.draft.slot, isNull);
    expect(find.byType(CheckoutSlotSheet), findsOneWidget);

    final freeChip = find.byKey(const ValueKey<String>('2026-09-22/t1'));
    expect(
      tester.getSemantics(freeChip),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: false,
      ),
    );
    await tester.tap(freeChip);
    await tester.pumpAndSettle();

    expect(checkoutCubit.state.draft.slot, free);
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.scheduled);
    expect(find.byType(CheckoutSlotSheet), findsNothing);
    semantics.dispose();
  });

  testWidgets('the bar shows "—" until the destination is priced', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await checkoutCubit.start();
    await pump(tester);

    expect(inBar(find.text('—')), findsOneWidget);
    expect(inBar(find.bySemanticsLabel('KD 2.600')), findsNothing);

    await tester.runAsync(() => checkoutCubit.selectAddress('a1'));
    await tester.pumpAndSettle();

    expect(inBar(find.bySemanticsLabel('KD 2.600')), findsOneWidget);
    // The dash stays mounted (hidden) under the amount, out of semantics.
    expect(inBar(find.bySemanticsLabel('—')), findsNothing);
    semantics.dispose();
  });

  testWidgets('the sheets fit a 360 × 800 phone at 1.3× text (ar)', (
    tester,
  ) async {
    Intl.defaultLocale = 'ar';
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester, locale: ar, size: const Size(360, 800), textScale: 1.3);

    final schedule = find.text('جدولة');
    await tester.scrollUntilVisible(
      schedule,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(schedule);
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSlotSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    // ✕ closes it the way a barrier tap does: nothing booked.
    await tester.tap(find.byType(JameiaCloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSlotSheet), findsNothing);
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.asap);

    await tester.runAsync(() => checkoutCubit.setMode(FulfillmentMode.pickup));
    await tester.pumpAndSettle();
    final chooseBranch = find.text('اختر الفرع');
    await tester.scrollUntilVisible(
      chooseBranch,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(chooseBranch);
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutBranchSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion: pickup lands at once, nothing keeps ticking', (
    tester,
  ) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester, reduceMotion: true);
    expect(find.text('When'), findsOneWidget);

    await tester.runAsync(() => checkoutCubit.setMode(FulfillmentMode.pickup));
    await tester.pump();
    await tester.pump();

    expect(find.text('Pick up from'), findsOneWidget);
    expect(find.text('Deliver to'), findsNothing);
    expect(find.text('When'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
