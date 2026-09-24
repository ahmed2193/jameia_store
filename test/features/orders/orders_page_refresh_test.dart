// The orders tab lives in the shell's IndexedStack: it is built once and
// never disposed, so an order placed, cancelled or reviewed on another
// screen happens behind its back. Stepping back onto the tab must re-read
// the list; leaving it must cost nothing.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
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
import 'package:jameia_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/get_order_usecase.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:jameia_mart/src/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:jameia_mart/src/features/orders/presentation/pages/orders_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository repository;
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    repository = FakeOrdersRepository();
    cartRepository = FakeCartRepository();
    cartCubit = CartCubit(
      watch: WatchCartUseCase(cartRepository),
      restore: RestoreCartUseCase(cartRepository),
      syncOwner: SyncCartOwnerUseCase(cartRepository),
      fetch: FetchCartUseCase(cartRepository),
      flush: FlushCartUseCase(cartRepository),
      adjustLine: AdjustCartLineUseCase(cartRepository),
      setLineQuantity: SetCartLineQuantityUseCase(cartRepository),
      removeLine: RemoveCartLineUseCase(cartRepository),
      addItems: AddCartItemsUseCase(cartRepository),
      clear: ClearCartUseCase(cartRepository),
      applyCoupon: ApplyCartCouponUseCase(cartRepository),
      removeCoupon: RemoveCartCouponUseCase(cartRepository),
      applyLoyalty: ApplyCartLoyaltyUseCase(cartRepository),
      removeLoyalty: RemoveCartLoyaltyUseCase(cartRepository),
      setExpress: SetCartExpressUseCase(cartRepository),
      reset: ResetCartUseCase(cartRepository),
    );
    // The page resolves its cubit from the locator, like every page does.
    sl.registerFactory<OrdersCubit>(
      () => OrdersCubit(
        getOrders: GetOrdersUseCase(repository),
        getOrder: GetOrderUseCase(repository),
        cancelOrder: CancelOrderUseCase(repository),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  Future<void> pump(WidgetTester tester, {required bool active}) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          child: BlocProvider<CartCubit>.value(
            value: cartCubit,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: OrdersPage(active: active),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  int listCalls() =>
      repository.calls.where((call) => call.startsWith('getOrders')).length;

  testWidgets('coming back to the tab re-reads the list', (tester) async {
    await pump(tester, active: true);
    final afterOpen = listCalls();
    expect(afterOpen, 1);

    // Another tab is showing …
    await pump(tester, active: false);
    expect(listCalls(), afterOpen, reason: 'leaving the tab costs nothing');

    // … and the customer comes back to Orders.
    await pump(tester, active: true);

    expect(listCalls(), afterOpen + 1);
  });

  testWidgets('staying on the tab does not re-read on every rebuild', (
    tester,
  ) async {
    await pump(tester, active: true);
    final afterOpen = listCalls();

    await pump(tester, active: true);
    await pump(tester, active: true);

    expect(listCalls(), afterOpen);
  });
}
