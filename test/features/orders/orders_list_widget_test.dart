// The orders API pages one flat list; the tabs slice it by status group. A
// tab must ask for the next page when its end is reached — never from a
// build pass, and never in an unbounded chain.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
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

  Future<void> pump(WidgetTester tester, OrderStatusGroup group) async {
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
                home: Scaffold(
                  body: OrdersList(
                    key: ValueKey<OrderStatusGroup>(group),
                    group: group,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a tab with rows never pages from a build pass', (tester) async {
    repository.pages = 5; // the server has plenty more
    await cubit.load();
    final afterFirstPage = repository.calls.length;

    await pump(tester, OrderStatusGroup.inProgress);

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

  testWidgets('an empty tab fills itself, but only for a few pages', (
    tester,
  ) async {
    repository.pages = 50; // a long history with nothing cancelled in it
    await cubit.load();

    await pump(tester, OrderStatusGroup.cancelled);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    // Bounded: the tab never walks the whole history looking for a row.
    expect(repository.calls.length, greaterThan(1));
    expect(repository.calls.length, lessThanOrEqualTo(5));
  });
}
