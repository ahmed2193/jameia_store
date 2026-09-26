// Shared wiring for the checkout widget tests: the app-global cubits the
// checkout body reads, built over scripted fakes, and a pump that mounts the
// body the way the app does.
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/core/domain/entities/jameia_address_entity.dart';
import 'package:jameia_mart/src/features/address/domain/entities/address_book.dart';
import 'package:jameia_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/add_cart_items_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/adjust_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/fetch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/flush_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/reset_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/restore_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_express_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_line_quantity_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/sync_cart_owner_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/watch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_branches_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_delivery_slots_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/place_order_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/select_delivery_address_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/select_pickup_branch_usecase.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';

import '../address/address_test_fakes.dart';
import '../auth/auth_test_fakes.dart';
import '../cart/fake_cart_repository.dart';
import 'fake_checkout_repository.dart';

const Locale checkoutEn = Locale('en');
const Locale checkoutAr = Locale('ar');

/// The saved address the checkout opens on (`defaultAddressId: 'a1'`).
const JameiaAddressEntity checkoutHome = JameiaAddressEntity(
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
    );

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

/// The checkout body over the four cubits, under a one-route router (the
/// sheets close through go_router's `context.pop`), in [locale], on a [size]
/// screen at [textScale], with the OS "remove animations" flag when
/// [reduceMotion]. Settles before returning.
Future<void> pumpCheckoutBody(
  WidgetTester tester, {
  required CartCubit cart,
  required CheckoutCubit checkout,
  required AuthSessionCubit session,
  required AddressBookCubit addressBook,
  Locale locale = checkoutEn,
  Size size = const Size(480, 2400),
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: CheckoutBody()),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.runAsync(() async {
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
            BlocProvider<CheckoutCubit>.value(value: checkout),
            BlocProvider<AuthSessionCubit>.value(value: session),
            BlocProvider<AddressBookCubit>.value(value: addressBook),
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
}
