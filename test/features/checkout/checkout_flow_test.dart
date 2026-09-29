// Flows that cross the checkout's sections (plan G6, motion spec §7.2): a
// rail "+" wakes only its card, the strip and the bar (CT-R2) and flies the
// card's own picture (CT-I2); a blocked "Place order" brings the missing
// destination back into view and shakes it (CT-K1); only a customer's own
// tap buzzes (CT-H4); and a guest who taps the address row lands on the
// address list's sign-in prompt, not on a dead end [prod C5].
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/shake_x.dart';
import 'package:hero_mart/src/core/responsive/app_size.dart';
import 'package:hero_mart/src/core/widgets/catalog_product_card.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_submit_button.dart';
import 'package:hero_mart/src/core/widgets/shelf_add_button.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/pages/address_list_page.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_rail_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_address_section.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_total.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_eta_row.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_hint_bubble.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_button.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_rail_section.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_rail_tile.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_section.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_thumb_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import '../address/address_test_fakes.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';
import 'fake_checkout_repository.dart';

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

/// On-sale products for the rail, each with its own picture.
const CatalogProductEntity _cheese = CatalogProductEntity(
  id: 'cheese',
  slug: 'cheese',
  name: 'Cheese puff',
  image: 'https://cdn/cheese.png',
  priceFils: 1400,
  compareAtFils: 2000,
  stock: 4,
);
const CatalogProductEntity _flour = CatalogProductEntity(
  id: 'flour',
  slug: 'flour',
  name: 'Flour',
  image: 'https://cdn/flour.png',
  priceFils: 630,
  compareAtFils: 1000,
  stock: 7,
);

/// A cart over [lines] with a 0.500 delivery fee and the server's coupon
/// discount.
CartEntity _cart({
  List<CartLineEntity> lines = const [_rice, _oil],
  CartCouponEntity? coupon,
  int couponFils = 0,
}) {
  final subtotal = lines.fold<int>(0, (sum, line) => sum + line.lineTotalFils);
  return CartEntity(
    itemCount: lines.fold<int>(0, (sum, line) => sum + line.quantity),
    lines: lines,
    coupon: coupon,
    totals: CartTotalsEntity(
      subtotalFils: subtotal,
      couponDiscountFils: couponFils,
      discountFils: couponFils,
      deliveryFeeFils: 500,
      baseDeliveryFeeFils: 500,
      totalFils: subtotal - couponFils + 500,
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

  CartSnapshot snapshotOf(CartEntity cart, {bool pending = false}) =>
      CartSnapshot(
        cart: cart,
        isRestored: true,
        hasPendingChanges: pending,
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

  /// A settled rail over [products].
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

  /// The page, priced at address a1 unless [priced] is off.
  Future<void> pump(
    WidgetTester tester, {
    bool priced = true,
    CheckoutRailCubit? rail,
    AddressBookCubit? book,
    List<RouteBase> extraRoutes = const <RouteBase>[],
    Size size = const Size(480, 2400),
  }) async {
    await checkoutCubit.start(defaultAddressId: priced ? 'a1' : null);
    await pumpCheckoutBody(
      tester,
      cart: cartCubit,
      checkout: checkoutCubit,
      session: session,
      addressBook: book ?? addressBook,
      rail: rail,
      extraRoutes: extraRoutes,
      size: size,
    );
  }

  /// Pushes [cart] the way the repository stream delivers it.
  Future<void> emit(
    WidgetTester tester,
    CartEntity cart, {
    bool pending = false,
  }) async {
    await tester.runAsync(() async {
      cartRepository.push(snapshotOf(cart, pending: pending));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  /// Every haptic the platform is asked for.
  List<Object?> recordHaptics(WidgetTester tester) {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return haptics;
  }

  Finder tile(String id) => find.byWidgetPredicate(
    (widget) => widget is CheckoutRailTile && widget.product.id == id,
  );

  Future<void> tapAdd(WidgetTester tester, String id) => tester.tap(
    find.descendant(of: tile(id), matching: find.byType(ShelfAddButton)),
  );

  /// The [HeroImage]s showing [product]'s picture.
  Iterable<HeroImage> imagesOf(
    WidgetTester tester,
    CatalogProductEntity product,
  ) => tester
      .widgetList<HeroImage>(find.byType(HeroImage))
      .where((image) => image.url == product.image);

  testWidgets('CT-R2: a rail add rebuilds its card, the strip and the bar, '
      'nothing else', (tester) async {
    await pump(tester, rail: await railOf(tester, const [_cheese, _flour]));
    // A tile selects its quantity with its own BlocSelector, so it is its
    // card that rebuilds; the tile widget, like the rail, stays.
    final probe = RebuildProbe<Widget, Object>(
      (widget) => switch (widget) {
        CheckoutRailTile(:final product) => 'tile:${product.id}',
        CatalogProductCard(:final product) => 'card:${product.id}',
        _ => widget.runtimeType,
      },
    )..start();
    addTearDown(probe.stop);

    await tapAdd(tester, 'cheese');
    // The cart's local projection lands at once, still on its way.
    await emit(
      tester,
      _cart(
        lines: const [
          _rice,
          _oil,
          CartLineEntity(
            key: 'l3',
            product: _cheese,
            quantity: 1,
            unitPriceFils: 1400,
            lineTotalFils: 1400,
          ),
        ],
      ),
      pending: true,
    );
    await tester.pump();

    expect(cartRepository.calls, contains('adjust:cheese::1'));
    expect(probe.of('card:cheese'), greaterThanOrEqualTo(1));
    expect(probe.of('card:flour'), 0);
    expect(probe.of('tile:cheese'), 0);
    expect(probe.of('tile:flour'), 0);
    // The strip selects inside its LayoutBuilder: the new line's slot is
    // what rebuilds.
    expect(probe.of(CheckoutThumbSlot), greaterThanOrEqualTo(1));
    expect(probe.of(CheckoutBarTotal), greaterThanOrEqualTo(1));
    for (final type in const <Type>[
      CheckoutRailSection,
      CheckoutBody,
      CheckoutEtaRow,
      CheckoutSavingsSection,
    ]) {
      expect(probe.of(type), 0, reason: '$type rebuilt on a rail add');
    }
    expect(probe.of(CheckoutPlaceButton), lessThanOrEqualTo(2));
    await tester.pumpAndSettle();
  });

  testWidgets(
    "CT-I2: the flying thumbnail asks for the tile's own image size",
    (tester) async {
      await pump(tester, rail: await railOf(tester, const [_cheese, _flour]));
      expect(imagesOf(tester, _cheese), hasLength(1));

      await tapAdd(tester, 'cheese');
      await tester.pump();

      // The card and its flight, both at the card's 130 dp: one decode.
      final images = imagesOf(tester, _cheese).toList();
      expect(images, hasLength(2));
      for (final image in images) {
        expect(image.width, CatalogProductCard.defaultWidth);
        expect(image.height, CatalogProductCard.defaultWidth);
      }
      expect(images.where((image) => image.width == AppSize.s56), isEmpty);
      await tester.pumpAndSettle();
      // Landed: only the card is left.
      expect(imagesOf(tester, _cheese), hasLength(1));
    },
  );

  testWidgets('CT-K1: a blocked Place order brings the missing section into '
      'view and shakes it', (tester) async {
    await emit(tester, _cart(lines: const [_riceOnSale, _oil]));
    await pump(tester, priced: false, size: const Size(480, 800));
    expect(find.byType(CheckoutHintBubble), findsOneWidget);

    // The page scrolled (by the page, not a drag: the hint stays) until the
    // address row is out of view.
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CheckoutBody),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(_scrolled);
    await tester.pump();
    // Out of view but still built (the viewport's cache keeps its block).
    final row = find.byType(CheckoutAddressSection, skipOffstage: false);
    expect(tester.getRect(row).bottom, lessThan(0));
    final haptics = recordHaptics(tester);

    await tester.tap(find.byType(HeroSubmitButton));
    await tester.pump();
    expect(haptics, hasLength(1));

    // The row shakes while the page scrolls back to it.
    final shake = find
        .ancestor(of: row, matching: find.byType(ShakeX, skipOffstage: false))
        .first;
    final swing = find
        .descendant(
          of: shake,
          matching: find.byType(Transform, skipOffstage: false),
          skipOffstage: false,
        )
        .first;
    var widest = 0.0;
    for (var t = Duration.zero; t < AppMotion.medium; t += _step) {
      await tester.pump(_step);
      final dx = tester.widget<Transform>(swing).transform.getTranslation().x;
      if (dx.abs() > widest) widest = dx.abs();
    }
    expect(widest, greaterThan(0));
    expect(scrollable.position.pixels, lessThan(_scrolled));

    await tester.pumpAndSettle();
    expect(tester.getRect(row).top, greaterThanOrEqualTo(0));
    expect(haptics, hasLength(1));
    // A scroll the page makes is not the customer's: the hint stays.
    expect(find.byType(CheckoutHintBubble), findsOneWidget);
    expect(checkoutCubit.state.draft.hasDestination, isFalse);
  });

  testWidgets('CT-H4: passive updates fire no haptic; a rail "+" fires one', (
    tester,
  ) async {
    await pump(
      tester,
      priced: false,
      rail: await railOf(tester, const [_cheese, _flour]),
    );
    final haptics = recordHaptics(tester);

    // The quote lands …
    await tester.runAsync(() => checkoutCubit.selectAddress('a1'));
    await tester.pumpAndSettle();
    // … a coupon arrives with a re-price …
    await emit(
      tester,
      _cart(
        coupon: const CartCouponEntity(code: 'SAVE', discountFils: 500),
        couponFils: 500,
      ),
    );
    await tester.pumpAndSettle();
    // … and the server re-prices a line.
    await emit(
      tester,
      _cart(
        lines: [_rice.withQuantity(3), _oil],
        coupon: const CartCouponEntity(code: 'SAVE', discountFils: 500),
        couponFils: 500,
      ),
    );
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);

    await tapAdd(tester, 'flour');
    await tester.pumpAndSettle();
    expect(haptics, <Object?>['HapticFeedbackType.selectionClick']);
  });

  testWidgets("a guest's address row reaches the address list's sign-in "
      'prompt', (tester) async {
    final guestBook = AddressBookCubit(
      getCached: FakeGetCachedAddressesUseCase(),
      getAddresses: FakeGetAddressesUseCase(
        const Left(UnauthorizedFailure('Sign in')),
      ),
      updateAddress: FakeUpdateAddressUseCase(const Right(checkoutHome)),
      deleteAddress: FakeDeleteAddressUseCase(),
      saveCache: FakeSaveCachedAddressesUseCase(),
      clearCache: FakeClearCachedAddressesUseCase(),
    );
    addTearDown(guestBook.close);
    await pump(
      tester,
      priced: false,
      book: guestBook,
      extraRoutes: [
        GoRoute(
          path: Routes.addressList,
          builder: (_, _) => const AddressListPage(),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login page')),
        ),
      ],
    );
    expect(checkoutCubit.state.draft.hasDestination, isFalse);

    await tester.tap(find.byType(CheckoutAddressSection));
    await _settle(tester);
    expect(find.byType(AddressListPage), findsOneWidget);
    expect(
      find.text('Sign in to see and manage your saved addresses'),
      findsOneWidget,
    );

    await tester.tap(find.text('Sign in'));
    await _settle(tester);
    expect(find.text('login page'), findsOneWidget);
  });
}

/// How far the page is scrolled before the blocked tap: the address row is
/// out of view, its block still built.
const double _scrolled = 240;

/// One step of the shake sampling.
const Duration _step = Duration(milliseconds: 10);

/// Lets a page with a loading skeleton settle (its shimmer never stops).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
