// The cart as the Cart tab's default view: no app bar of its own, so the item
// count and "clear" sit over the lines, and an empty cart sends the customer
// back to shopping.
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
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
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/pages/cart_tab_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import 'cart_test_fixtures.dart';
import 'fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;
  late CartCubit cartCubit;
  late AuthSessionCubit session;
  late int browses;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    browses = 0;
    // The loyalty row reads the signed-in customer's points.
    session = AuthSessionCubit(
      restoreSession: FakeRestoreSessionUseCase(const Right(null)),
      logout: FakeLogoutUseCase(),
      watchExpiry: FakeWatchSessionExpiryUseCase(),
      getCachedCustomer: FakeGetCachedCustomerUseCase(),
      saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
      clearCachedCustomer: FakeClearCachedCustomerUseCase(),
    );
    repository = FakeCartRepository();
    cartCubit = CartCubit(
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
  });

  tearDown(() async {
    await session.close();
    await cartCubit.close();
    await repository.dispose();
  });

  Future<void> pump(WidgetTester tester, CartSnapshot snapshot) async {
    repository.push(snapshot);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CartCubit>.value(value: cartCubit),
              BlocProvider<AuthSessionCubit>.value(value: session),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: CartTabPage(onBrowse: () => browses++),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    // Not pumpAndSettle: a product image shimmers until it loads, which it
    // never does without a network.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a cart with lines shows the count and the clear action', (
    tester,
  ) async {
    await pump(
      tester,
      const CartSnapshot(
        cart: CartEntity(
          itemCount: 2,
          lines: <CartLineEntity>[
            CartLineEntity(
              key: 'l1',
              product: testProduct,
              quantity: 2,
              unitPriceFils: 1500,
              lineTotalFils: 3000,
            ),
          ],
        ),
        isRestored: true,
      ),
    );

    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('Clear cart'), findsOneWidget);
    expect(find.text('Basmati rice'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('an empty cart offers to start shopping', (tester) async {
    await pump(tester, const CartSnapshot(isRestored: true));

    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.text('Start shopping'));

    expect(browses, 1);
  });
}
