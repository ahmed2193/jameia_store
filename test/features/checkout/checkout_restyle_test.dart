// The Hero-style checkout as a whole page: where and when on top, then the
// order summary, instant savings and the scalloped order totals, payment,
// additional options and "good to know" on white blocks over grey bands, and
// the pinned bar whose total stays hidden until the server priced the
// destination. Timing, the note and the items live in sheets. It reads the
// same in Arabic (money stays one left-to-right run) and fits a 360 dp phone
// at 1.3× text.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/delivery_slot_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/hero_close_button.dart';
import 'package:hero_mart/src/core/widgets/hero_money_text.dart';
import 'package:hero_mart/src/core/widgets/option_row.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_branch_sheet.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_card_text.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_row.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_mode_toggle.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_payment_icon.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_order_bar.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_receipt.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_slot_chip.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_slot_sheet.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_timing_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

/// One frame at 60 Hz.
const Duration _frame = Duration(milliseconds: 16);

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

  Finder inToggle(Finder matching) =>
      find.descendant(of: find.byType(CheckoutModeToggle), matching: matching);

  Finder inEtaRow(Finder matching) =>
      find.descendant(of: find.byType(CheckoutEtaRow), matching: matching);

  /// The "Expected" row → the timing sheet → "Schedule" → the slot sheet.
  Future<void> openSlotSheet(WidgetTester tester, String schedule) async {
    await tester.tap(find.byType(CheckoutEtaRow));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutTimingSheet), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(CheckoutTimingSheet),
        matching: find.text(schedule),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every section in English', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    expect(inToggle(find.text('Delivery')), findsOneWidget);
    expect(inToggle(find.text('Pickup')), findsOneWidget);
    // An address is chosen: its row, not the prompt.
    expect(find.text('Choose a delivery address'), findsNothing);
    expect(inEtaRow(find.text('Expected')), findsOneWidget);
    expect(inEtaRow(find.text('45 min')), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
    // Rice × 2 + oil × 1; the rows themselves live in the items sheet.
    expect(find.text('3 pcs'), findsOneWidget);
    expect(find.text('Basmati rice'), findsNothing);
    expect(find.text('Instant savings'), findsOneWidget);
    expect(find.text('Coupons & offers'), findsOneWidget);
    expect(find.text('Order totals'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('Cash on delivery'), findsOneWidget);
    expect(find.text('Additional options'), findsOneWidget);
    expect(find.text('Notes for the store'), findsOneWidget);
    expect(find.text('Good to know'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Terms of service'), findsOneWidget);
    expect(inBar(find.text('Place order')), findsOneWidget);
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
        // One scroll view for the whole page.
        expect(find.byType(CustomScrollView), findsOneWidget);
        // Scroll through the whole page so every section is laid out.
        for (var i = 0; i < 8; i++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(
          find.byType(CheckoutReceipt, skipOffstage: false),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('the mode switch moves the page to pickup', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);
    expect(find.byType(CheckoutEtaCardText), findsOneWidget);

    await tester.tap(inToggle(find.text('Pickup')));
    await tester.pumpAndSettle();

    expect(checkoutCubit.state.draft.mode, FulfillmentMode.pickup);
    expect(find.text('Choose a branch'), findsOneWidget);
    expect(find.text('Choose a delivery address'), findsNothing);
    // Pickup has no delivery timing: no card, and the row only informs.
    expect(find.byType(CheckoutEtaCardText), findsNothing);
    expect(inEtaRow(find.text('Ready for pickup')), findsOneWidget);
    expect(inEtaRow(find.text('Expected')), findsNothing);
    await tester.tap(find.byType(CheckoutEtaRow));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutTimingSheet), findsNothing);
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
    // Each method leads with its mark (the cash note, the wallet plate).
    for (final row in [cod, wallet]) {
      expect(
        find.descendant(of: row, matching: find.byType(CheckoutPaymentIcon)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: cod, matching: find.byIcon(HeroIcons.cash)),
      findsOneWidget,
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

    await openSlotSheet(tester, 'Schedule');
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

    await tester.scrollUntilVisible(
      inEtaRow(find.text('الوصول المتوقع')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await openSlotSheet(tester, 'جدولة');
    expect(find.byType(CheckoutSlotSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    // ✕ in the floating disc closes it the way a barrier tap does: nothing
    // booked.
    await tester.tap(find.byType(HeroCloseButton));
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
    expect(inEtaRow(find.text('Expected')), findsOneWidget);
    expect(find.byType(CheckoutEtaCardText), findsOneWidget);

    await tester.runAsync(() => checkoutCubit.setMode(FulfillmentMode.pickup));
    await tester.pump();
    await tester.pump();

    expect(find.text('Choose a branch'), findsOneWidget);
    expect(find.text('Choose a delivery address'), findsNothing);
    expect(inEtaRow(find.text('Ready for pickup')), findsOneWidget);
    expect(find.byType(CheckoutEtaCardText), findsNothing);
    // Unpriced again, the bar's total and the receipt's figures swap to
    // "—" through a fade-through: a plain AppMotion.fast fade under
    // reduced motion (the one documented exception). An animation reports
    // done on the first frame past its duration; then nothing ticks.
    await tester.pump(AppMotion.fast);
    await tester.pump(_frame);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
