// The checkout's motion across its sections (plan G6, motion spec §7.2):
// a background sync or an equal copy of the cart rebuilds no section
// (CT-R1), a re-price that changes no quantity leaves the thumbs alone
// (CT-R3), the thumbs start static and animate only what changed (CT-TH1),
// a coupon applied after open plays once across the savings card, the
// receipt and the bar (CT-V1), and with "remove animations" on every change
// lands at once (T-RM).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/core/motion/rolling_number.dart';
import 'package:jameia_mart/src/core/motion/rotating_line.dart';
import 'package:jameia_mart/src/core/utils/formatters.dart';
import 'package:jameia_mart/src/core/widgets/catalog_product_card.dart';
import 'package:jameia_mart/src/core/widgets/jameia_image.dart';
import 'package:jameia_mart/src/core/widgets/shelf_add_button.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_offers_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_rail_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_address_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_fact_text.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_total.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_card.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_hint_bubble.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_info_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_note_row.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_options_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_order_summary.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_payment_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_pieces_label.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_order_bar.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_rail_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_rail_tile.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_receipt.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_figure.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_hint.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_section.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumb_slot.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumb_tile.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumbs_strip.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_unlock_tag.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_where_when_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';
import 'fake_checkout_repository.dart';

/// One frame at 60 Hz: an animation reports done on the first frame past
/// its duration.
const Duration _frame = Duration(milliseconds: 16);

/// Every section of the page (the bar's total and button are left out: a
/// sync in flight rightly turns the total into "Updating…").
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
  CheckoutNoteRow,
  CheckoutInfoSection,
  CheckoutPlaceOrderBar,
];

const CartLineEntity _rice = CartLineEntity(
  key: 'l1',
  product: testProduct,
  quantity: 2,
  unitPriceFils: 600,
  lineTotalFils: 1200,
);

/// Rice on sale: 0.300 off each of its 2 pieces (the hint's line).
const CartLineEntity _riceOnSale = CartLineEntity(
  key: 'l1',
  product: testProduct,
  quantity: 2,
  unitPriceFils: 600,
  compareAtFils: 900,
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

/// An on-sale product for the rail, with its own picture.
const CatalogProductEntity _cheese = CatalogProductEntity(
  id: 'cheese',
  slug: 'cheese',
  name: 'Cheese puff',
  image: 'https://cdn/cheese.png',
  priceFils: 1400,
  compareAtFils: 2000,
  stock: 4,
);

/// `GET /v1/offers`: 10% off (up to 3.000) from a bigger basket.
const OfferEntity _percentOffer = OfferEntity(
  id: 'pct',
  name: 'Big basket',
  rewardType: OfferRewardType.percentageDiscount,
  percent: 10,
  maxDiscountFils: 3000,
  stackable: true,
);

/// The cart's progress towards [offerId], [remaining] fils away.
CartOfferProgressEntity _progress(String offerId, int remaining) =>
    CartOfferProgressEntity(
      offerId: offerId,
      name: offerId,
      kind: OfferProgressKind.subtotal,
      currentValue: 2100,
      targetValue: 2100 + remaining,
      remainingValue: remaining,
      reward: const OfferRewardEntity(type: OfferRewardType.percentageDiscount),
    );

/// A cart over [lines]: the goods, the server's coupon discount and a 0.500
/// delivery fee (waived when [freeDelivery]).
CartEntity _cart({
  List<CartLineEntity> lines = const [_rice, _oil],
  CartCouponEntity? coupon,
  int couponFils = 0,
  bool freeDelivery = false,
  List<CartOfferProgressEntity> offerProgress =
      const <CartOfferProgressEntity>[],
}) {
  final subtotal = lines.fold<int>(0, (sum, line) => sum + line.lineTotalFils);
  final delivery = freeDelivery ? 0 : 500;
  return CartEntity(
    itemCount: lines.fold<int>(0, (sum, line) => sum + line.quantity),
    lines: lines,
    coupon: coupon,
    offerProgress: offerProgress,
    totals: CartTotalsEntity(
      subtotalFils: subtotal,
      couponDiscountFils: couponFils,
      discountFils: couponFils,
      deliveryFeeFils: delivery,
      baseDeliveryFeeFils: 500,
      freeDelivery: freeDelivery,
      totalFils: subtotal - couponFils + delivery,
    ),
  );
}

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late CheckoutCubit checkoutCubit;
  late AuthSessionCubit session;
  late AddressBookCubit addressBook;
  var revision = 0;

  CartSnapshot snapshotOf(CartEntity cart, {bool syncing = false}) =>
      CartSnapshot(
        cart: cart,
        isRestored: true,
        isSyncing: syncing,
        revision: ++revision,
      );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()..snapshot = snapshotOf(_cart());
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

  /// A loaded page-scoped cubit over [catalog] (the rail and the offers).
  Future<CheckoutRailCubit> railOf(
    WidgetTester tester,
    List<CatalogProductEntity> products,
  ) async {
    final rail = buildRailCubit(
      FakeCheckoutCatalogRepository(products: products),
    );
    addTearDown(rail.close);
    await tester.runAsync(() => rail.load(excludeProductIds: const <String>{}));
    return rail;
  }

  Future<CheckoutOffersCubit> offersOf(
    WidgetTester tester,
    List<OfferEntity> offers,
  ) async {
    final cubit = buildOffersCubit(
      FakeCheckoutCatalogRepository(offers: offers),
    );
    addTearDown(cubit.close);
    await tester.runAsync(cubit.load);
    return cubit;
  }

  /// A priced checkout (address a1 selected) on a screen tall enough that
  /// every section is built.
  Future<void> pump(
    WidgetTester tester, {
    CheckoutRailCubit? rail,
    CheckoutOffersCubit? offers,
    bool reduceMotion = false,
  }) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pumpCheckoutBody(
      tester,
      cart: cartCubit,
      checkout: checkoutCubit,
      session: session,
      addressBook: addressBook,
      rail: rail,
      offers: offers,
      reduceMotion: reduceMotion,
    );
  }

  /// Pushes [cart] the way the repository stream delivers it.
  Future<void> emit(
    WidgetTester tester,
    CartEntity cart, {
    bool syncing = false,
  }) async {
    await tester.runAsync(() async {
      cartRepository.push(snapshotOf(cart, syncing: syncing));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  Finder inBar(Finder matching) => find.descendant(
    of: find.byType(CheckoutPlaceOrderBar),
    matching: matching,
  );

  Finder inStrip(Finder matching) =>
      find.descendant(of: find.byType(CheckoutThumbsStrip), matching: matching);

  Finder inReceipt(Finder matching) =>
      find.descendant(of: find.byType(CheckoutReceipt), matching: matching);

  Finder countUp() => find.descendant(
    of: find.byType(CheckoutSavingsFigure),
    matching: find.byType(TweenAnimationBuilder<double>),
  );

  Iterable<double> scalesUnder(WidgetTester tester, Finder of) => tester
      .widgetList<ScaleTransition>(
        find.descendant(of: of, matching: find.byType(ScaleTransition)),
      )
      .map((transition) => transition.scale.value);

  /// The fact shown on the bar's line (the first one while it rests).
  List<Object> shownFacts(WidgetTester tester) => tester
      .widgetList<CheckoutBarFactText>(inBar(find.byType(CheckoutBarFactText)))
      .map<Object>((text) => text.fact)
      .toList();

  testWidgets('CT-R1: sync-only snapshots rebuild no section', (tester) async {
    await pump(tester);
    final probe = RebuildProbe<Widget, Type>((widget) => widget.runtimeType)
      ..start();
    addTearDown(probe.stop);

    // A background sync starts, then lands with an equal copy of the cart
    // (a NEW lines list with the same content).
    await emit(tester, _cart(), syncing: true);
    await tester.pumpAndSettle();
    await emit(
      tester,
      _cart(lines: List<CartLineEntity>.of(const [_rice, _oil])),
    );
    await tester.pumpAndSettle();

    // The snapshots did reach the page: the bar's total said "Updating…".
    expect(probe.of(CheckoutBarTotal), greaterThan(0));
    for (final section in _sections) {
      expect(probe.of(section), 0, reason: '$section rebuilt on a sync');
    }
  });

  testWidgets('CT-R3: a re-price that changes no shown qty leaves the thumbs '
      'strip alone', (tester) async {
    await pump(tester);
    final probe = RebuildProbe<Widget, Type>((widget) => widget.runtimeType)
      ..start();
    addTearDown(probe.stop);

    // The server re-prices rice (0.600 → 0.650); every quantity stays.
    await emit(
      tester,
      _cart(
        lines: const [
          CartLineEntity(
            key: 'l1',
            product: testProduct,
            quantity: 2,
            unitPriceFils: 650,
            lineTotalFils: 1300,
          ),
          _oil,
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The receipt took the new subtotal …
    expect(inReceipt(find.text('KD 2.200')), findsOneWidget);
    // … the strip did not move.
    for (final type in const <Type>[
      CheckoutThumbsStrip,
      CheckoutThumbSlot,
      CheckoutThumbTile,
      CheckoutPiecesLabel,
    ]) {
      expect(probe.of(type), 0, reason: '$type rebuilt on a re-price');
    }
  });

  testWidgets('CT-TH1: thumbs: first build static; a new line pops into a '
      'free slot; a qty change bumps its badge and the pieces count', (
    tester,
  ) async {
    await pump(tester);
    // The first build is static: every slot at full size, nothing ticking.
    expect(scalesUnder(tester, find.byType(CheckoutThumbsStrip)), isNotEmpty);
    expect(
      scalesUnder(
        tester,
        find.byType(CheckoutThumbsStrip),
      ).every((s) => s == 1),
      isTrue,
    );
    expect(tester.hasRunningAnimations, isFalse);

    const dates = CartLineEntity(
      key: 'l3',
      product: _dates,
      quantity: 1,
      unitPriceFils: 700,
      lineTotalFils: 700,
    );
    await emit(tester, _cart(lines: const [_rice, _oil, dates]));
    await tester.pump(_frame);
    expect(
      scalesUnder(tester, find.byType(CheckoutThumbsStrip)).any((s) => s < 1),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(inStrip(find.byType(CheckoutThumbTile)), findsNWidgets(3));
    expect(find.text('4 pcs'), findsOneWidget);

    // Rice 2 → 3: its "3x" badge and the pieces count bump; nothing pops.
    await emit(tester, _cart(lines: [_rice.withQuantity(3), _oil, dates]));
    await tester.pump(AppMotion.medium ~/ 4);
    final riceBadge = find.ancestor(
      of: inStrip(find.text('3x')),
      matching: find.byType(CheckoutThumbTile),
    );
    expect(scalesUnder(tester, riceBadge).any((s) => s > 1), isTrue);
    expect(
      scalesUnder(tester, find.byType(CheckoutPiecesLabel)).any((s) => s > 1),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.text('5 pcs'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('CT-V1: voucher applied: the tag pops, the saving counts up, '
      'the receipt row opens, the total rolls once', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, offers: await offersOf(tester, [_percentOffer]));
    final roller = inBar(find.byType(RollingNumber));
    expect(roller, findsOneWidget);
    final rollerBefore = tester.element(roller);
    expect(countUp(), findsNothing);
    expect(inReceipt(find.text('Coupon SAVE')), findsNothing);

    await emit(
      tester,
      _cart(
        coupon: const CartCouponEntity(code: 'SAVE', discountFils: 500),
        couponFils: 500,
        offerProgress: [_progress('pct', 1500)],
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Mid-flight: the tag pops in, the figure counts up, the coupon row
    // opens in the receipt.
    expect(
      scalesUnder(
        tester,
        find.byType(CheckoutUnlockTag),
      ).any((s) => s > 0 && s < 1),
      isTrue,
    );
    expect(countUp(), findsOneWidget);
    final opening = tester
        .widgetList<SizeTransition>(
          find.ancestor(
            of: inReceipt(find.text('Coupon SAVE')),
            matching: find.byType(SizeTransition),
          ),
        )
        .map((transition) => transition.sizeFactor.value);
    expect(opening.any((f) => f > 0 && f < 1), isTrue);

    await tester.pumpAndSettle();
    final code = Formatters.isolate('SAVE');
    expect(find.text('$code · saved KD 0.500'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CheckoutSavingsSection),
        matching: find.bySemanticsLabel(RegExp('saved KD 0.500')),
      ),
      findsOneWidget,
    );
    expect(inReceipt(find.text('Coupon SAVE')), findsOneWidget);
    // The bar's total rolled in place: the same roller, the new amount.
    expect(identical(tester.element(roller), rollerBefore), isTrue);
    expect(inBar(find.bySemanticsLabel('KD 2.100')), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    semantics.dispose();
  });

  testWidgets('T-RM: reduced motion: every checkout change lands at once', (
    tester,
  ) async {
    // The rice on sale (the hint) and free delivery: two facts take turns
    // on the line (the savings, free delivery).
    // (The cart already listens: the next await delivers it.)
    cartRepository.push(
      snapshotOf(_cart(lines: const [_riceOnSale, _oil], freeDelivery: true)),
    );
    await pump(
      tester,
      rail: await railOf(tester, const [_cheese]),
      offers: await offersOf(tester, [_percentOffer]),
      reduceMotion: true,
    );

    // The hint is simply there: no pop, no float.
    expect(find.byType(CheckoutHintBubble), findsOneWidget);
    expect(
      scalesUnder(
        tester,
        find.byType(CheckoutSavingsHint),
      ).every((s) => s == 1),
      isTrue,
    );
    expect(tester.hasRunningAnimations, isFalse);

    // The line shows its first fact and never rotates.
    expect(inBar(find.byType(RotatingLine)), findsOneWidget);
    final first = shownFacts(tester);
    expect(first, hasLength(1));
    await tester.pump(const Duration(seconds: 10));
    expect(shownFacts(tester), first);
    expect(
      tester.state<RotatingLineState>(find.byType(RotatingLine)).debugResting,
      isFalse,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);

    // A coupon lands: the final figure and the receipt row after one frame,
    // no count-up.
    await emit(
      tester,
      _cart(
        lines: const [_riceOnSale, _oil],
        freeDelivery: true,
        coupon: const CartCouponEntity(code: 'SAVE', discountFils: 500),
        couponFils: 500,
        offerProgress: [_progress('pct', 1500)],
      ),
    );
    final code = Formatters.isolate('SAVE');
    expect(find.text('$code · saved KD 0.500'), findsOneWidget);
    expect(inReceipt(find.text('Coupon SAVE')), findsOneWidget);
    expect(countUp(), findsNothing);
    // Only a fade-through's plain AppMotion.fast fade may run.
    await tester.pump(AppMotion.fast);
    await tester.pump(_frame);
    expect(tester.hasRunningAnimations, isFalse);

    // A rail "+": the cart takes it, but no picture flies.
    final cheeseTile = find.byWidgetPredicate(
      (widget) => widget is CheckoutRailTile && widget.product.id == 'cheese',
    );
    await tester.tap(
      find.descendant(of: cheeseTile, matching: find.byType(ShelfAddButton)),
    );
    await tester.pump();
    expect(cartRepository.calls, contains('adjust:cheese::1'));
    final cheeseImages = tester
        .widgetList<JameiaImage>(find.byType(JameiaImage))
        .where((image) => image.url == _cheese.image);
    expect(cheeseImages, hasLength(1));
    expect(cheeseImages.single.width, CatalogProductCard.defaultWidth);
    await tester.pump(AppMotion.fast);
    await tester.pump(_frame);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
