// Timing on the Keeta-style checkout: the "Expected" row opens the timing
// sheet (ASAP / Express when the cart offers it / Schedule when the address
// has windows), Schedule goes on to the slot sheet, picking Schedule again
// reopens it with the booked window marked, a refused express puts timing
// AND window back, every option waits while the cart is busy, and the sheets
// reach the page-scoped CheckoutCubit (the harness provides it inside the
// route, like the page).
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/delivery_slot_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/utils/formatters.dart';
import 'package:jameia_mart/src/core/widgets/option_row.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_branch_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_slot_chip.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_slot_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_timing_sheet.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_where_when_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  late FakeCheckoutRepository checkoutRepository;
  late CartCubit cartCubit;
  late CheckoutCubit checkoutCubit;
  late AuthSessionCubit session;
  late AddressBookCubit addressBook;

  const totals = CartTotalsEntity(
    subtotalFils: 2100,
    deliveryFeeFils: 500,
    baseDeliveryFeeFils: 500,
    totalFils: 2600,
  );

  const morning = DeliverySlotEntity(
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
  const evening = DeliverySlotEntity(
    templateId: 't3',
    date: '2026-09-22',
    label: '18:00 – 20:00',
    remaining: 4,
    available: true,
  );

  /// A one-line cart; express offered (20 min, +1.500) unless [offered] is
  /// off.
  CartSnapshot snapshotOf({bool offered = true}) => CartSnapshot(
    cart: CartEntity(
      itemCount: 1,
      totals: totals,
      lines: const <CartLineEntity>[
        CartLineEntity(
          key: 'l1',
          product: testProduct,
          quantity: 1,
          unitPriceFils: 2100,
          lineTotalFils: 2100,
        ),
      ],
      expressOffered: offered,
      expressEtaMinutes: 20,
      expressSurchargeOfferedFils: 1500,
    ),
    isRestored: true,
  );

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(CheckoutTimingSheet), matching: matching);

  Finder chip(DeliverySlotEntity slot) =>
      find.byKey(ValueKey<String>('${slot.date}/${slot.templateId}'));

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  setUp(() {
    cartRepository = FakeCartRepository()..snapshot = snapshotOf();
    cartCubit = buildCartCubit(cartRepository);
    checkoutRepository = FakeCheckoutRepository()
      ..days = const <DeliverySlotDayEntity>[
        DeliverySlotDayEntity(
          date: '2026-09-22',
          label: 'Tomorrow',
          slots: <DeliverySlotEntity>[morning, full, evening],
        ),
      ];
    checkoutCubit = buildCheckoutCubit(checkoutRepository);
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

  Future<void> pump(WidgetTester tester) => pumpCheckoutSection(
    tester,
    const CheckoutWhereWhenBlock(),
    cart: cartCubit,
    checkout: checkoutCubit,
    session: session,
    addressBook: addressBook,
  );

  /// Delivers [next] to the app-global cart and settles.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  /// Taps the "Expected" row: the timing sheet opens.
  Future<void> openTiming(WidgetTester tester) async {
    await tester.tap(find.byType(CheckoutEtaRow));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutTimingSheet), findsOneWidget);
  }

  testWidgets('Schedule → the slot sheet books a window; Schedule again '
      'reopens it with that window marked, and a new one replaces it', (
    tester,
  ) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    await openTiming(tester);
    expect(inSheet(find.text('Delivery time')), findsOneWidget);
    expect(inSheet(find.text('As soon as possible')), findsOneWidget);
    expect(inSheet(find.text('About 45 min')), findsOneWidget);
    await tester.tap(inSheet(find.text('Schedule')));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutTimingSheet), findsNothing);
    expect(find.byType(CheckoutSlotSheet), findsOneWidget);
    expect(find.text('Delivery windows'), findsOneWidget);
    expect(find.byType(CheckoutSlotChip), findsNWidgets(3));
    expect(tester.widget<CheckoutSlotChip>(chip(full)).enabled, isFalse);
    await tester.tap(chip(morning));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutSlotSheet), findsNothing);
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.scheduled);
    expect(checkoutCubit.state.draft.slot, morning);
    // The row reads the booked window.
    expect(
      find.descendant(
        of: find.byType(CheckoutEtaRow),
        matching: find.text(
          'Tomorrow${Formatters.middot}'
          '${Formatters.isolate(morning.label)}',
        ),
      ),
      findsOneWidget,
    );

    // Schedule again: the slot sheet reopens with the booked one marked.
    await openTiming(tester);
    expect(
      tester
          .widget<OptionRow>(find.widgetWithText(OptionRow, 'Schedule'))
          .selected,
      isTrue,
    );
    await tester.tap(inSheet(find.text('Schedule')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSlotSheet), findsOneWidget);
    expect(
      tester
          .widget<CheckoutSlotSheet>(find.byType(CheckoutSlotSheet))
          .preselected,
      morning,
    );
    expect(tester.widget<CheckoutSlotChip>(chip(morning)).selected, isTrue);
    expect(tester.widget<CheckoutSlotChip>(chip(evening)).selected, isFalse);

    await tester.tap(chip(evening));
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.draft.slot, evening);
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.scheduled);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a dismissed slot sheet books nothing', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    await openTiming(tester);
    await tester.tap(inSheet(find.text('Schedule')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSlotSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10)); // the scrim
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSlotSheet), findsNothing);
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.asap);
    expect(checkoutCubit.state.draft.slot, isNull);
  });

  testWidgets('Express is offered only when the cart offers it, with its '
      'real minutes and fee', (tester) async {
    cartRepository.push(snapshotOf(offered: false));
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    await openTiming(tester);
    expect(inSheet(find.text('Express')), findsNothing);
    expect(inSheet(find.text('Schedule')), findsOneWidget);

    await emit(tester, snapshotOf());
    expect(inSheet(find.text('Express')), findsOneWidget);
    expect(
      inSheet(find.text('About 20 min · +${Formatters.price(1.5)}')),
      findsOneWidget,
    );

    await tester.tap(inSheet(find.text('Express')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutTimingSheet), findsNothing);
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.express);
    expect(cartRepository.calls, contains('express:true'));
  });

  testWidgets('express refused while scheduled: timing and window both come '
      'back', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    await openTiming(tester);
    await tester.tap(inSheet(find.text('Schedule')));
    await tester.pumpAndSettle();
    await tester.tap(chip(morning));
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.draft.slot, morning);

    cartRepository.failure = const ServerFailure('express unavailable');
    await openTiming(tester);
    await tester.tap(inSheet(find.text('Express')));
    await tester.pumpAndSettle();

    expect(cartRepository.calls, contains('express:true'));
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.scheduled);
    expect(checkoutCubit.state.draft.slot, morning);
  });

  testWidgets('every timing option waits while the cart is busy', (
    tester,
  ) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    final gate = Completer<void>();
    cartRepository.gate = gate;
    final coupon = cartCubit.applyCoupon('SAVE');
    await tester.pump();
    expect(cartCubit.state.isBusy, isTrue);

    await openTiming(tester);
    final options = tester.widgetList<OptionRow>(
      inSheet(find.byType(OptionRow)),
    );
    expect(options, hasLength(3));
    expect(options.every((option) => !option.enabled), isTrue);

    // A tap on a waiting option does nothing.
    await tester.tap(inSheet(find.text('Express')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutTimingSheet), findsOneWidget);
    expect(checkoutCubit.state.draft.timing, DeliveryTiming.asap);

    gate.complete();
    await coupon;
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<OptionRow>(inSheet(find.byType(OptionRow)))
          .every((option) => option.enabled),
      isTrue,
    );
  });

  testWidgets('the sheets reach the page-scoped CheckoutCubit', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    await openTiming(tester);
    expect(
      BlocProvider.of<CheckoutCubit>(
        tester.element(find.byType(CheckoutTimingSheet)),
      ),
      same(checkoutCubit),
    );
    await tester.tap(inSheet(find.text('Schedule')));
    await tester.pumpAndSettle();
    expect(
      BlocProvider.of<CheckoutCubit>(
        tester.element(find.byType(CheckoutSlotSheet)),
      ),
      same(checkoutCubit),
    );
    await tester.tap(chip(evening));
    await tester.pumpAndSettle();

    // Pickup: the branch row opens the branch sheet over the same cubit.
    await tester.tap(find.text('Pickup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a branch'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutBranchSheet), findsOneWidget);
    expect(find.text('Branches'), findsOneWidget);
    expect(
      BlocProvider.of<CheckoutCubit>(
        tester.element(find.byType(CheckoutBranchSheet)),
      ),
      same(checkoutCubit),
    );
    await tester.tap(find.text('Salmiya'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutBranchSheet), findsNothing);
    expect(checkoutCubit.state.draft.branchId, 'b1');
    expect(checkoutRepository.calls, contains('branch:b1'));
    expect(tester.takeException(), isNull);
  });
}
