// Rebuild scope of the orders list (perf spec T5): the list selects the
// value-equal feed, so a refresh that brings back the same orders — a pull,
// the tab coming back, a row refreshed on the way back from tracking —
// rebuilds no card and starts no animation. A row whose status did move
// rebuilds, and its tag cross-fades.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
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
import 'package:hero_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/cancel_order_sheet.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/order_card.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/order_status_chip.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/orders_list.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_orders_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_order_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
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
    repository = FakeOrdersRepository()
      ..statuses = <String>['placed', 'delivered', 'cancelled'];
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
      watchFirstPage: WatchOrdersUseCase(repository),
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
    // The first page's cascade plays and ends here.
    await tester.pumpAndSettle();
  }

  testWidgets('an unchanged refresh rebuilds no card and plays nothing', (
    tester,
  ) async {
    await cubit.load();
    await pump(tester);
    expect(find.byType(OrderCard), findsNWidgets(3));

    final cards = RebuildProbe<OrderCard, String>((card) => card.order.id)
      ..start();
    addTearDown(cards.stop);

    // A pull / the tab coming back: the same three orders again.
    await tester.runAsync(cubit.refresh);
    await tester.pump();
    expect(cards.total, 0);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);

    // Back from tracking: the row answers with the status it already had.
    await tester.runAsync(() => cubit.refreshOrder('o0'));
    await tester.pump();
    expect(cards.total, 0);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    cards.stop();
  });

  testWidgets('a status that moved rebuilds its card and fades its tag', (
    tester,
  ) async {
    await cubit.load();
    await pump(tester);

    final cards = RebuildProbe<OrderCard, String>((card) => card.order.id)
      ..start();
    addTearDown(cards.stop);

    repository.detailStatus = 'cancelled';
    await tester.runAsync(() => cubit.refreshOrder('o0'));
    await tester.pump();

    expect(cards.of('o0'), 1);
    // The rows whose order did not move keep their card as it was.
    expect(cards.of('o1'), 0);
    expect(cards.of('o2'), 0);
    // The tag cross-fades and the card eases to its new actions.
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
    cards.stop();

    await tester.pumpAndSettle();
    final chip = tester.widget<OrderStatusChip>(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is OrderCard && widget.order.id == 'o0',
        ),
        matching: find.byType(OrderStatusChip),
      ),
    );
    expect(chip.status, OrderStatus.cancelled);
    expect(find.byType(OrderStatusChip), findsNWidgets(3));
  });

  testWidgets('the next page rebuilds none of the cards already shown', (
    tester,
  ) async {
    repository
      ..statuses = <String>['placed', 'delivered']
      ..pages = 2; // page 2 brings one more order, `o2`
    await cubit.load();
    await pump(tester);
    expect(find.byType(OrderCard), findsNWidgets(2));

    final cards = RebuildProbe<OrderCard, String>((card) => card.order.id)
      ..start();
    addTearDown(cards.stop);

    await tester.runAsync(cubit.loadMore);
    await tester.pump();

    expect(cubit.state.feed.orders.map((order) => order.id), [
      'o0',
      'o1',
      'o2',
    ]);
    expect(cards.of('o0'), 0);
    expect(cards.of('o1'), 0);
    cards.stop();
    await tester.pumpAndSettle();
    expect(find.byType(OrderCard), findsNWidgets(3));
  });

  testWidgets('the keyboard sliding up rebuilds none of the cancel sheet', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await cubit.load(); // `o0` is placed: it can be cancelled
    await pump(tester);
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    expect(find.byType(CancelOrderSheet), findsOneWidget);
    final scrollArea = find.descendant(
      of: find.byType(CancelOrderSheet),
      matching: find.byType(SingleChildScrollView),
    );
    final restingHeight = tester.getSize(scrollArea).height;

    final sheets = RebuildProbe<CancelOrderSheet, String>(
      (sheet) => sheet.orderId,
    )..start();
    addTearDown(sheets.stop);

    // A few frames of the keyboard animation.
    for (final bottom in <double>[300, 600, 900]) {
      tester.view.viewInsets = FakeViewPadding(bottom: bottom);
      await tester.pump();
    }

    expect(sheets.total, 0);
    sheets.stop();
    // Only the inset moved: the scrolling content still ends above the
    // keyboard.
    expect(tester.getSize(scrollArea).height, lessThan(restingHeight));
  });
}
