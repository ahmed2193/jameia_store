// The orders API pages one flat list and the screen shows all of it. The
// list must ask for the next page when its end is reached — never from a
// build pass — and every status must be in it, each row wearing its own.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:jameia_mart/src/features/orders/presentation/widgets/orders_list/order_card.dart';
import 'package:jameia_mart/src/features/orders/presentation/widgets/orders_list/order_status_chip.dart';
import 'package:jameia_mart/src/features/orders/presentation/widgets/orders_list/orders_list.dart';
import 'package:jameia_mart/src/features/orders/presentation/widgets/orders_list/orders_load_more_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository repository;
  late OrdersCubit cubit;
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    repository = FakeOrdersRepository();
    cartRepository = FakeCartRepository();
    // The cards offer "reorder", which is a cart action.
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
    cubit = OrdersCubit(
      getOrders: GetOrdersUseCase(repository),
      getOrder: GetOrderUseCase(repository),
      cancelOrder: CancelOrderUseCase(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    // EasyLocalization reads its JSON from the bundle: let that real async
    // work finish before the fake clock takes over.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<OrdersCubit>.value(value: cubit),
              BlocProvider<CartCubit>.value(value: cartCubit),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: OrdersList()),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a list with rows never pages from a build pass', (tester) async {
    repository.pages = 5; // the server has plenty more
    await cubit.load();
    final afterFirstPage = repository.calls.length;

    await pump(tester);

    // Drawing the list asks for nothing: paging follows the scroll (or the
    // customer's tap), never a build pass.
    expect(repository.calls.length, afterFirstPage);
    expect(find.byType(OrdersLoadMoreRow), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.calls.length, afterFirstPage);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(repository.calls.length, afterFirstPage + 1);
  });

  testWidgets('every status is in the one list, with its own chip', (
    tester,
  ) async {
    repository.statuses = <String>['placed', 'delivered', 'cancelled'];
    await cubit.load();

    await pump(tester);

    // No tabs to switch: the three orders are on screen together.
    expect(find.byType(OrderCard), findsNWidgets(3));
    expect(find.byType(OrderStatusChip), findsNWidgets(3));
    expect(find.byType(TabBar), findsNothing);
  });
}
