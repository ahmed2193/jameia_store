// The restyled orders list: a title bar only when the page is pushed, each
// status wearing its own tag tone and its own actions (no empty gap when it
// has none), a centred empty state that still pulls to refresh, a cancel
// sheet that scrolls over the keyboard, Arabic money read left-to-right, no
// overflow at 360 dp with large text, a first-page cascade that never plays
// for rows built later, and a hidden history that ticks nothing.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade_item.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/app_button.dart';
import 'package:hero_mart/src/core/widgets/hero_money_text.dart';
import 'package:hero_mart/src/core/widgets/hero_secondary_button.dart';
import 'package:hero_mart/src/core/widgets/hero_tag.dart';
import 'package:hero_mart/src/core/widgets/hero_title_bar.dart';
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
import 'package:hero_mart/src/features/orders/presentation/pages/orders_page.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/cancel_order_sheet.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/order_actions.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/order_card.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/order_status_chip.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/orders_empty_view.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/orders_list.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_orders_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_order_usecase.dart';
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
    await initializeDateFormatting('ar');
  });

  OrdersCubit newOrdersCubit() => OrdersCubit(
    watchFirstPage: WatchOrdersUseCase(repository),
    getOrders: GetOrdersUseCase(repository),
    getOrder: GetOrderUseCase(repository),
    cancelOrder: CancelOrderUseCase(repository),
  );

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
    cubit = newOrdersCubit();
    // Pages resolve their cubit from the locator, like every page does.
    sl.registerFactory<OrdersCubit>(newOrdersCubit);
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await sl.reset();
    await cubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  /// [home] under EasyLocalization with the orders + cart cubits, as the
  /// root route of a GoRouter (the sheets close with `context.pop()`).
  /// [settle] false stops right after the frame that first builds [home]
  /// (a cascade just started, or a loading shimmer that never settles).
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool reducedMotion = false,
    bool settle = true,
  }) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => home)],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: locale,
          saveLocale: false,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<OrdersCubit>.value(value: cubit),
              BlocProvider<CartCubit>.value(value: cartCubit),
            ],
            child: Builder(
              builder: (context) => MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale),
                    viewInsets: viewInsets,
                    disableAnimations: reducedMotion,
                  ),
                  child: child!,
                ),
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    // The translations load from the real asset bundle: give that real
    // async work the turns it needs before [home] can build.
    for (
      var turn = 0;
      turn < 50 && find.byWidget(home).evaluate().isEmpty;
      turn++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(find.byWidget(home), findsOneWidget);
    if (settle) await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester, {double height = 800}) {
    tester.view.physicalSize = Size(360, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder cardOf(String id) => find.byWidgetPredicate(
    (widget) => widget is OrderCard && widget.order.id == id,
  );

  List<String> actionLabels(String id) => [
    for (final button
        in find
            .descendant(
              of: cardOf(id),
              matching: find.byType(HeroSecondaryButton),
            )
            .evaluate())
      (button.widget as HeroSecondaryButton).label,
  ];

  group('OrdersPage', () {
    testWidgets('standalone (not embedded) it wears the title bar', (
      tester,
    ) async {
      await pump(tester, const OrdersPage());

      expect(find.byType(HeroTitleBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HeroTitleBar),
          matching: find.text('Orders'),
        ),
        findsOneWidget,
      );
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(OrderCard), findsOneWidget);
    });

    testWidgets('embedded in the Cart tab it draws no bar', (tester) async {
      await pump(tester, const OrdersPage(embedded: true));

      expect(find.byType(HeroTitleBar), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(OrderCard), findsOneWidget);
    });

    testWidgets('a hidden history ticks nothing while it loads', (
      tester,
    ) async {
      final gate = Completer<void>();
      repository.listGate = gate; // the skeleton (a shimmer) stays up
      // The shell keeps every tab in an IndexedStack; slot 1 is showing.
      final shown = ValueNotifier<int>(1);
      addTearDown(shown.dispose);

      await pump(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: shown,
          builder: (_, index, _) => IndexedStack(
            index: index,
            children: const [OrdersPage(embedded: true), SizedBox.shrink()],
          ),
        ),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(OrdersPage, skipOffstage: false), findsOneWidget);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);

      // The history tab comes back on screen: the shimmer runs again (it
      // starts once the skeleton's own loaderDelay wait is over).
      shown.value = 0;
      await tester.pump(AppMotion.loaderDelay);
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

      await tester.runAsync(() async {
        gate.complete();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(find.byType(OrderCard), findsOneWidget);
    });
  });

  group('OrdersList', () {
    testWidgets('each status gets its own actions; none leaves no gap', (
      tester,
    ) async {
      phone(tester, height: 2000);
      repository.statuses = <String>[
        'placed',
        'delivered',
        'cancelled',
        'out_for_delivery',
      ];
      await cubit.load();

      await pump(tester, const Scaffold(body: OrdersList()));

      expect(actionLabels('o0'), ['Cancel order']);
      expect(actionLabels('o1'), ['Rate products', 'Reorder']);
      expect(actionLabels('o2'), ['Reorder']);
      expect(actionLabels('o3'), isEmpty);
      Finder actionsOf(String id) =>
          find.descendant(of: cardOf(id), matching: find.byType(OrderActions));
      expect(tester.getSize(actionsOf('o3')).height, 0);
      expect(tester.getSize(actionsOf('o0')).height, greaterThan(0));
      // No TextButton inside a card: Load more stays the list's only one.
      expect(
        find.descendant(of: cardOf('o0'), matching: find.byType(TextButton)),
        findsNothing,
      );
    });

    testWidgets('the status tag tone follows the status group', (tester) async {
      phone(tester, height: 2000);
      repository.statuses = <String>[
        'placed',
        'delivered',
        'cancelled',
        'delivery_failed',
      ];
      await cubit.load();

      await pump(tester, const Scaffold(body: OrdersList()));

      HeroTagTone toneOf(String id) => tester
          .widget<HeroTag>(
            find.descendant(
              of: find.descendant(
                of: cardOf(id),
                matching: find.byType(OrderStatusChip),
              ),
              matching: find.byType(HeroTag),
            ),
          )
          .tone;
      expect(toneOf('o0'), HeroTagTone.brandSoft);
      expect(toneOf('o1'), HeroTagTone.neutral);
      expect(toneOf('o2'), HeroTagTone.error);
      expect(toneOf('o3'), HeroTagTone.error);
    });

    testWidgets('no orders: centred, and a pull still refreshes', (
      tester,
    ) async {
      repository.statuses = <String>[]; // the first page is empty
      await cubit.load();
      await pump(tester, const Scaffold(body: OrdersList()));

      expect(find.text('No orders yet'), findsOneWidget);
      final area = tester.getRect(find.byType(OrdersEmptyView));
      final message = tester.getRect(find.text('No orders yet'));
      // The block sits in the middle of the list area, not at its top.
      expect(message.top, greaterThan(area.top + area.height / 4));
      expect(message.bottom, lessThan(area.bottom - area.height / 4));

      final before = repository.calls.length;
      await tester.fling(
        find.text('No orders yet'),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(repository.calls.length, before + 1);
      expect(repository.calls.last, 'getOrders:1');
    });

    testWidgets('renders in Arabic, right-to-left, money left-to-right', (
      tester,
    ) async {
      Intl.defaultLocale = 'ar';
      repository.statuses = <String>['placed', 'delivered'];
      await cubit.load();

      await pump(
        tester,
        const Scaffold(body: OrdersList()),
        locale: const Locale('ar'),
      );

      final card = find.byType(OrderCard).first;
      expect(Directionality.of(tester.element(card)), TextDirection.rtl);
      final money = find.descendant(
        of: find.descendant(of: card, matching: find.byType(HeroMoneyText)),
        matching: find.byType(Text),
      );
      expect(money, findsOneWidget);
      expect(Directionality.of(tester.element(money)), TextDirection.ltr);
      expect(tester.widget<Text>(money).data, startsWith('د.ك'));
      expect(find.text('إعادة الطلب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 360 dp with 1.3× text, en and ar', (
      tester,
    ) async {
      phone(tester);
      repository.statuses = <String>['placed', 'delivered', 'cancelled'];
      repository.pages = 2;
      await cubit.load();

      await pump(tester, const Scaffold(body: OrdersList()), textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.byType(OrderCard), findsWidgets);

      Intl.defaultLocale = 'ar';
      await pump(
        tester,
        const Scaffold(body: OrdersList()),
        locale: const Locale('ar'),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('only the first page cascades in; later rows are static', (
      tester,
    ) async {
      repository.pages = 2;
      await cubit.load();

      await pump(tester, const Scaffold(body: OrdersList()), settle: false);
      Widget builtBy(Finder item) {
        late Widget child;
        tester.element(item).visitChildElements((e) => child = e.widget);
        return child;
      }

      final first = find.byKey(const ValueKey<String>('o1'));
      expect(tester.widget(first), isA<EntranceCascadeItem>());
      expect(builtBy(first), isA<FadeTransition>());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      final appended = find.byKey(const ValueKey<String>('o2'));
      expect(appended, findsOneWidget);
      expect(builtBy(appended), isA<OrderCard>());
    });

    testWidgets('a first order that arrives on a refresh does not cascade', (
      tester,
    ) async {
      repository.statuses = <String>[]; // no history yet
      await cubit.load();
      await pump(tester, const Scaffold(body: OrdersList()));
      expect(find.byType(OrdersEmptyView), findsOneWidget);

      // The customer ordered meanwhile; the tab comes back / a pull.
      repository.statuses = <String>['placed'];
      await tester.runAsync(cubit.refresh);
      await tester.pump();

      final item = find.byKey(const ValueKey<String>('o0'));
      expect(tester.widget(item), isA<EntranceCascadeItem>());
      late Widget child;
      tester.element(item).visitChildElements((e) => child = e.widget);
      expect(child, isA<OrderCard>());
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion: nothing cascades, nothing runs', (
      tester,
    ) async {
      repository.statuses = <String>['placed', 'delivered'];
      await cubit.load();

      await pump(
        tester,
        const Scaffold(body: OrdersList()),
        reducedMotion: true,
        settle: false,
      );

      final item = find.byKey(const ValueKey<String>('o0'));
      late Widget child;
      tester.element(item).visitChildElements((e) => child = e.widget);
      expect(child, isA<OrderCard>());
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('CancelOrderSheet', () {
    testWidgets('scrolls over the keyboard at 360×640 and sends the reason', (
      tester,
    ) async {
      phone(tester, height: 640);
      await cubit.load(); // one `placed` order: it can be cancelled

      await pump(
        tester,
        const Scaffold(body: OrdersList()),
        textScale: 1.3,
        viewInsets: const EdgeInsets.only(bottom: 300),
      );
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      expect(find.byType(CancelOrderSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Why are you cancelling?'), findsOneWidget);
      // However tall, it stops short of the status bar.
      expect(
        tester.getTopLeft(find.byType(CancelOrderSheet)).dy,
        greaterThanOrEqualTo(640 * 0.15 - 1),
      );

      // Over the keyboard only part of the sheet shows: scroll to the row.
      await tester.ensureVisible(find.text('Taking too long'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taking too long'));
      await tester.pumpAndSettle();
      final confirm = find.descendant(
        of: find.byType(CancelOrderSheet),
        matching: find.byType(AppButton),
      );
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(CancelOrderSheet), findsNothing);
      expect(repository.calls, contains('cancel:o1:too_slow'));
      expect(tester.takeException(), isNull);
    });
  });
}
