// Shared wiring for the checkout widget tests: the app-global cubits the
// checkout reads, built over scripted fakes, and pumps that mount the body
// (or one section of it) the way the app does — the app-global cubits above
// MaterialApp, the page-scoped ones (checkout, rail, offers and the UI
// controller) INSIDE the route, exactly like `CheckoutPage` provides them.
// A sheet is a new route, so it only reaches the page-scoped cubits when the
// widget that opens it passes them on (`CheckoutSheetFrame.show(checkout:)`).
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/domain/entities/hero_address_entity.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_book.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/add_cart_items_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/adjust_cart_line_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/apply_cart_coupon_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/apply_cart_loyalty_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/fetch_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/flush_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/remove_cart_coupon_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/remove_cart_line_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/remove_cart_loyalty_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/reset_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/restore_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/set_cart_express_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/set_cart_line_quantity_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/sync_cart_owner_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/watch_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/get_branches_usecase.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/get_delivery_slots_usecase.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/get_rail_products_usecase.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/get_store_offers_usecase.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/get_store_rules_usecase.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/place_order_usecase.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/select_delivery_address_usecase.dart';
import 'package:hero_mart/src/features/checkout/domain/usecases/select_pickup_branch_usecase.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_offers_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_rail_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_ui_controller.dart';

import '../address/address_test_fakes.dart';
import '../auth/auth_test_fakes.dart';
import '../cart/fake_cart_repository.dart';
import 'fake_checkout_catalog_repository.dart';
import 'fake_checkout_repository.dart';

const Locale checkoutEn = Locale('en');
const Locale checkoutAr = Locale('ar');

/// The saved address the checkout opens on (`defaultAddressId: 'a1'`).
const HeroAddressEntity checkoutHome = HeroAddressEntity(
  id: 'a1',
  label: 'Home',
);

/// The app-global cart over [repository], started (it restores the
/// repository's snapshot).
CartCubit buildCartCubit(FakeCartRepository repository) => CartCubit(
  watch: WatchCartUseCase(repository),
  restore: RestoreCartUseCase(repository),
  syncOwner: SyncCartOwnerUseCase(repository),
  fetch: FetchCartUseCase(repository),
  flush: FlushCartUseCase(repository),
  adjustLine: AdjustCartLineUseCase(repository),
  setLineQuantity: SetCartLineQuantityUseCase(repository),
  removeLine: RemoveCartLineUseCase(repository),
  addItems: AddCartItemsUseCase(repository),
  clear: ClearCartUseCase(repository),
  applyCoupon: ApplyCartCouponUseCase(repository),
  removeCoupon: RemoveCartCouponUseCase(repository),
  applyLoyalty: ApplyCartLoyaltyUseCase(repository),
  removeLoyalty: RemoveCartLoyaltyUseCase(repository),
  setExpress: SetCartExpressUseCase(repository),
  reset: ResetCartUseCase(repository),
)..start();

/// The page's checkout cubit over [repository], not started yet.
CheckoutCubit buildCheckoutCubit(FakeCheckoutRepository repository) =>
    CheckoutCubit(
      getBranches: GetBranchesUseCase(repository),
      getDeliverySlots: GetDeliverySlotsUseCase(repository),
      selectDeliveryAddress: SelectDeliveryAddressUseCase(repository),
      selectPickupBranch: SelectPickupBranchUseCase(repository),
      placeOrder: PlaceOrderUseCase(repository),
      getStoreRules: GetStoreRulesUseCase(repository),
    );

/// The page's rail cubit over [repository], not loaded yet.
CheckoutRailCubit buildRailCubit(FakeCheckoutCatalogRepository repository) =>
    CheckoutRailCubit(GetRailProductsUseCase(repository));

/// The page's offers cubit over [repository], not loaded yet.
CheckoutOffersCubit buildOffersCubit(
  FakeCheckoutCatalogRepository repository,
) => CheckoutOffersCubit(GetStoreOffersUseCase(repository));

/// A signed-out session; tests sign a customer in when they need one.
AuthSessionCubit buildSessionCubit() => AuthSessionCubit(
  restoreSession: FakeRestoreSessionUseCase(const Right(null)),
  logout: FakeLogoutUseCase(),
  watchExpiry: FakeWatchSessionExpiryUseCase(),
  getCachedCustomer: FakeGetCachedCustomerUseCase(),
  saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
  clearCachedCustomer: FakeClearCachedCustomerUseCase(),
);

/// An address book holding [checkoutHome].
AddressBookCubit buildAddressBookCubit() => AddressBookCubit(
  getCached: FakeGetCachedAddressesUseCase(),
  getAddresses: FakeGetAddressesUseCase(const Right(AddressBook.empty)),
  updateAddress: FakeUpdateAddressUseCase(const Right(checkoutHome)),
  deleteAddress: FakeDeleteAddressUseCase(),
  saveCache: FakeSaveCachedAddressesUseCase(),
  clearCache: FakeClearCachedAddressesUseCase(),
)..applySaved(checkoutHome);

/// The checkout body over the app-global cubits and the page-scoped ones,
/// under a one-route router (the sheets close through go_router's
/// `context.pop`), in [locale], on a [size] screen at [textScale], with the
/// OS "remove animations" flag when [reduceMotion]. Settles before
/// returning, and returns the page's UI controller.
///
/// [session] / [addressBook] / [rail] / [offers] default to fresh ones (a
/// guest, the [checkoutHome] book, a settled empty rail, no offers) that
/// are closed after the test.
Future<CheckoutUiController> pumpCheckoutBody(
  WidgetTester tester, {
  required CartCubit cart,
  required CheckoutCubit checkout,
  AuthSessionCubit? session,
  AddressBookCubit? addressBook,
  CheckoutRailCubit? rail,
  CheckoutOffersCubit? offers,
  DateTime Function()? clock,
  List<RouteBase> extraRoutes = const <RouteBase>[],
  Locale locale = checkoutEn,
  Size size = const Size(480, 2400),
  double textScale = 1,
  bool reduceMotion = false,
}) => _pumpCheckout(
  tester,
  body: const CheckoutBody(),
  cart: cart,
  checkout: checkout,
  session: session,
  addressBook: addressBook,
  rail: rail,
  offers: offers,
  clock: clock,
  extraRoutes: extraRoutes,
  locale: locale,
  size: size,
  textScale: textScale,
  reduceMotion: reduceMotion,
);

/// One checkout section ([child]) with everything [pumpCheckoutBody]
/// provides. [inScrollView]: the section sits in a `CustomScrollView` as
/// the body's slivers do; off, it sits at the bottom of the screen (the
/// place-order bar). [extraRoutes] are added to the router (a stub page for
/// a route the section pushes). Returns the page's UI controller.
Future<CheckoutUiController> pumpCheckoutSection(
  WidgetTester tester,
  Widget child, {
  required CartCubit cart,
  required CheckoutCubit checkout,
  AuthSessionCubit? session,
  AddressBookCubit? addressBook,
  CheckoutRailCubit? rail,
  CheckoutOffersCubit? offers,
  DateTime Function()? clock,
  bool inScrollView = true,
  List<RouteBase> extraRoutes = const <RouteBase>[],
  Locale locale = checkoutEn,
  Size size = const Size(480, 2400),
  double textScale = 1,
  bool reduceMotion = false,
}) => _pumpCheckout(
  tester,
  body: inScrollView
      ? CustomScrollView(slivers: <Widget>[SliverToBoxAdapter(child: child)])
      : Column(
          children: <Widget>[
            const Expanded(child: SizedBox.shrink()),
            child,
          ],
        ),
  cart: cart,
  checkout: checkout,
  session: session,
  addressBook: addressBook,
  rail: rail,
  offers: offers,
  clock: clock,
  extraRoutes: extraRoutes,
  locale: locale,
  size: size,
  textScale: textScale,
  reduceMotion: reduceMotion,
);

Future<CheckoutUiController> _pumpCheckout(
  WidgetTester tester, {
  required Widget body,
  required CartCubit cart,
  required CheckoutCubit checkout,
  required AuthSessionCubit? session,
  required AddressBookCubit? addressBook,
  required CheckoutRailCubit? rail,
  required CheckoutOffersCubit? offers,
  required DateTime Function()? clock,
  required List<RouteBase> extraRoutes,
  required Locale locale,
  required Size size,
  required double textScale,
  required bool reduceMotion,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final sessionCubit = session ?? _closeAfter(buildSessionCubit());
  final book = addressBook ?? _closeAfter(buildAddressBookCubit());
  final railCubit =
      rail ?? _closeAfter(buildRailCubit(FakeCheckoutCatalogRepository()));
  final offersCubit =
      offers ?? _closeAfter(buildOffersCubit(FakeCheckoutCatalogRepository()));
  final ui = CheckoutUiController(clock: clock);
  addTearDown(ui.dispose);

  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        // Page-scoped providers live inside the route, like CheckoutPage.
        builder: (_, _) => RepositoryProvider<CheckoutUiController>.value(
          value: ui,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CheckoutCubit>.value(value: checkout),
              BlocProvider<CheckoutRailCubit>.value(value: railCubit),
              BlocProvider<CheckoutOffersCubit>.value(value: offersCubit),
            ],
            child: Scaffold(body: body),
          ),
        ),
      ),
      ...extraRoutes,
    ],
  );
  addTearDown(router.dispose);
  await tester.runAsync(() async {
    // The defaults settle the way the page's do before its content shows.
    if (rail == null) await railCubit.load(excludeProductIds: const {});
    if (offers == null) await offersCubit.load();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[checkoutEn, checkoutAr],
        path: 'assets/i18n',
        fallbackLocale: checkoutEn,
        startLocale: locale,
        saveLocale: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cart),
            BlocProvider<AuthSessionCubit>.value(value: sessionCubit),
            BlocProvider<AddressBookCubit>.value(value: book),
          ],
          child: Builder(
            builder: (context) => MaterialApp.router(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: reduceMotion,
                ),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
    // A language file's first load takes a few real event-loop turns.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
  return ui;
}

/// Closes a harness-made cubit after the test.
T _closeAfter<T extends BlocBase<Object?>>(T cubit) {
  addTearDown(cubit.close);
  return cubit;
}
