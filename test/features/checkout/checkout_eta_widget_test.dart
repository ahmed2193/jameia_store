// Block A of the Hero-style checkout: the flat destination row, the
// "Expected" row with its express mark and minutes, the ETA card whose clock
// time follows a minute clock, the maintenance banner, pickup, a closed
// branch and reduced motion — all through the block itself
// (`pumpCheckoutSection(const CheckoutWhereWhenBlock())`).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/utils/formatters.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/branch_entity.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_badge.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_card_text.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_row.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_maintenance_banner.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_timing_sheet.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_where_when_block.dart';
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

  /// 2.100 of goods with a 0.500 delivery fee.
  const totals = CartTotalsEntity(
    subtotalFils: 2100,
    deliveryFeeFils: 500,
    baseDeliveryFeeFils: 500,
    totalFils: 2600,
  );

  /// A one-line cart with the given express / branch facts.
  CartSnapshot snapshotOf({
    bool expressOffered = false,
    bool expressSelected = false,
    int? expressEtaMinutes,
    bool branchOpen = true,
  }) => CartSnapshot(
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
      expressOffered: expressOffered,
      expressSelected: expressSelected,
      expressEtaMinutes: expressEtaMinutes,
      expressSurchargeOfferedFils: 1500,
      branchOpen: branchOpen,
    ),
    isRestored: true,
  );

  Finder inRow(Finder matching) =>
      find.descendant(of: find.byType(CheckoutEtaRow), matching: matching);

  /// Delivers [next] to the app-global cart (its stream was subscribed in
  /// the real zone) and settles.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  setUp(() {
    cartRepository = FakeCartRepository()..snapshot = snapshotOf();
    cartCubit = buildCartCubit(cartRepository);
    checkoutRepository = FakeCheckoutRepository();
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

  /// The block over the app-global cubits and the page's checkout.
  Future<void> pump(
    WidgetTester tester, {
    DateTime Function()? clock,
    bool reduceMotion = false,
  }) async {
    await pumpCheckoutSection(
      tester,
      const CheckoutWhereWhenBlock(),
      cart: cartCubit,
      checkout: checkoutCubit,
      session: session,
      addressBook: addressBook,
      clock: clock,
      reduceMotion: reduceMotion,
    );
  }

  testWidgets('"Expected · 45 min" once the address is priced', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    expect(inRow(find.text('Expected')), findsOneWidget);
    expect(inRow(find.text('45 min')), findsOneWidget);
    // ASAP: the Hero clock, no express mark, a chevron to the timing sheet.
    Finder svg(String asset) => find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          (widget.bytesLoader as SvgAssetLoader).assetName == asset,
    );
    expect(inRow(svg(HeroAssets.sharedClock)), findsOneWidget);
    expect(inRow(svg(HeroAssets.checkoutExpressBolt)), findsNothing);
    expect(inRow(find.text('Express')), findsNothing);
    expect(inRow(find.byIcon(Icons.chevron_right_rounded)), findsOneWidget);
    // The destination row is the flat one: the chosen address, no prompt.
    expect(find.text('Choose a delivery address'), findsNothing);
    expect(find.byType(CheckoutEtaCardText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('before an address: "Choose an address first", no card', (
    tester,
  ) async {
    await checkoutCubit.start();
    await pump(tester);

    expect(find.text('Choose a delivery address'), findsOneWidget);
    expect(inRow(find.text('Choose an address first')), findsOneWidget);
    expect(find.byType(CheckoutEtaCardText), findsNothing);
  });

  testWidgets('express: the bolt only when it beats the standard estimate, '
      'else a plain "Express" tag', (tester) async {
    cartRepository.push(
      snapshotOf(
        expressOffered: true,
        expressSelected: true,
        expressEtaMinutes: 20,
      ),
    );
    await checkoutCubit.start(defaultAddressId: 'a1', expressSelected: true);
    await pump(tester);

    final badge = find.byType(CheckoutEtaBadge);
    expect(inRow(find.text('20 min')), findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: badge, matching: find.text('Express')),
      findsNothing,
    );

    // Slower than the address's 45 min: no "faster" bolt, just the tag.
    await emit(
      tester,
      snapshotOf(
        expressOffered: true,
        expressSelected: true,
        expressEtaMinutes: 60,
      ),
    );
    expect(inRow(find.text('60 min')), findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.byType(SvgPicture)),
      findsNothing,
    );
    expect(
      find.descendant(of: badge, matching: find.text('Express')),
      findsOneWidget,
    );

    // Express off the order: no mark at all.
    await emit(tester, snapshotOf(expressOffered: true));
    expect(
      find.descendant(of: badge, matching: find.byType(SvgPicture)),
      findsNothing,
    );
    expect(
      find.descendant(of: badge, matching: find.text('Express')),
      findsNothing,
    );
  });

  testWidgets('pickup: "Ready for pickup", no chevron, no card, no tap; the '
      'branch row shows the phone', (tester) async {
    checkoutRepository.branches = const <BranchEntity>[
      BranchEntity(
        id: 'b1',
        name: 'Salmiya',
        address: 'Block 10',
        phone: '+96522223333',
        supportsPickup: true,
      ),
    ];
    await checkoutCubit.start();
    await checkoutCubit.selectBranch('b1');
    await pump(tester);

    expect(checkoutCubit.state.draft.mode, FulfillmentMode.pickup);
    expect(inRow(find.text('Ready for pickup')), findsOneWidget);
    expect(inRow(find.text('45 min')), findsOneWidget);
    expect(inRow(find.text('Expected')), findsNothing);
    expect(inRow(find.byIcon(Icons.chevron_right_rounded)), findsNothing);
    expect(find.byType(CheckoutEtaCardText), findsNothing);
    expect(find.text('Salmiya'), findsOneWidget);
    expect(find.textContaining('+96522223333'), findsOneWidget);
    expect(find.textContaining('Block 10'), findsOneWidget);

    await tester.tap(find.byType(CheckoutEtaRow));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutTimingSheet), findsNothing);
  });

  testWidgets('the card: 10:03 + 45 min arrives around 10:50; five minutes '
      'later it says 10:55', (tester) async {
    var now = DateTime(2026, 9, 26, 10, 3);
    await checkoutCubit.start();
    await pump(tester, clock: () => now);
    expect(find.byType(CheckoutEtaCardText), findsNothing);

    // Priced after the page is up: the card (and its minute clock) mounts
    // under the test's clock.
    await checkoutCubit.selectAddress('a1');
    await tester.pumpAndSettle();
    String arrives(int hour, int minute) =>
        'Arrives around '
        '${Formatters.clock('en', DateTime(2026, 9, 26, hour, minute))}';
    expect(find.text(arrives(10, 50)), findsOneWidget);
    expect(
      find.text('An estimate. Times can vary by area and branch.'),
      findsOneWidget,
    );

    now = DateTime(2026, 9, 26, 10, 8);
    await tester.pump(const Duration(minutes: 5));
    expect(find.text(arrives(10, 55)), findsOneWidget);
    expect(find.text(arrives(10, 50)), findsNothing);
  });

  testWidgets('a closed branch: the row says so, no card', (tester) async {
    cartRepository.push(snapshotOf(branchOpen: false));
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    expect(inRow(find.text('The branch is closed right now')), findsOneWidget);
    expect(inRow(find.text('45 min')), findsNothing);
    expect(find.byType(CheckoutEtaCardText), findsNothing);
  });

  testWidgets('maintenance: a banner with the server message', (tester) async {
    checkoutRepository.rules = const CheckoutStoreRules(
      maintenance: true,
      maintenanceMessage: 'Back at 6 PM.',
    );
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    expect(
      find.descendant(
        of: find.byType(CheckoutMaintenanceBanner),
        matching: find.text('Back at 6 PM.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('maintenance without a message: the app line; none otherwise', (
    tester,
  ) async {
    checkoutRepository.rules = const CheckoutStoreRules(maintenance: true);
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);
    expect(find.text('The store is closed for maintenance'), findsOneWidget);
  });

  testWidgets('no maintenance: no banner', (tester) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);
    expect(
      find.descendant(
        of: find.byType(CheckoutMaintenanceBanner),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
  });

  testWidgets('reduced motion: switching to pickup lands at once', (
    tester,
  ) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester, reduceMotion: true);
    expect(find.byType(CheckoutEtaCardText), findsOneWidget);

    await tester.runAsync(() => checkoutCubit.setMode(FulfillmentMode.pickup));
    await tester.pump();
    await tester.pump();

    expect(find.text('Choose a branch'), findsOneWidget);
    expect(inRow(find.text('Ready for pickup')), findsOneWidget);
    expect(find.byType(CheckoutEtaCardText), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
