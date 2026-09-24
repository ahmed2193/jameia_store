// The Cart tab opens on the cart and switches to the order history. The
// history must not be fetched before the customer asks for it, must keep its
// state once built, and must know when it is the view on screen (it reloads on
// that edge).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/config/routes/route_args/shell_tabs.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
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
import 'package:jameia_mart/src/features/shell/presentation/widgets/shell_basket_tab.dart';
import 'package:jameia_mart/src/features/shell/presentation/widgets/shell_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';

/// Stands in for the orders page: says whether it was told it is on screen,
/// and keeps a counter in its State so the test can see that State survive.
class _FakeHistory extends StatefulWidget {
  const _FakeHistory({required this.active});

  final bool active;

  @override
  State<_FakeHistory> createState() => _FakeHistoryState();
}

class _FakeHistoryState extends State<_FakeHistory> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps++),
    child: Text('history active=${widget.active} taps=$taps'),
  );
}

void main() {
  late FakeCartRepository repository;
  late CartCubit cartCubit;
  late List<bool> historyBuilds;
  late int browses;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    historyBuilds = <bool>[];
    browses = 0;
    repository = FakeCartRepository()
      ..snapshot = const CartSnapshot(
        cart: CartEntity(itemCount: 3),
        isRestored: true,
      );
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
    await cartCubit.close();
    await repository.dispose();
  });

  ShellTabs tabs() => ShellTabs(
    home: (_) => const Text('home'),
    search: (_) => const Text('search'),
    cart: (onBrowse) =>
        TextButton(onPressed: onBrowse, child: const Text('the cart')),
    orderHistory: (active) {
      historyBuilds.add(active);
      return _FakeHistory(active: active);
    },
    mine: (_) => const Text('mine'),
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
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
                home: Scaffold(body: child),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  Widget basket({bool active = true}) =>
      ShellBasketTab(tabs: tabs(), active: active, onBrowse: () => browses++);

  testWidgets('opens on the cart and does not build the history yet', (
    tester,
  ) async {
    await pump(tester, basket());

    expect(find.text('the cart'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Order history'), findsOneWidget);
    // The history is what would call GET /v1/orders: not before it is asked.
    expect(historyBuilds, isEmpty);
  });

  testWidgets('the switch carries the cart count', (tester) async {
    await pump(tester, basket());

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('choosing the history shows it, on screen', (tester) async {
    await pump(tester, basket());

    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();

    expect(find.text('history active=true taps=0'), findsOneWidget);
    expect(historyBuilds.last, isTrue);
  });

  testWidgets('going back to the cart keeps the history alive, off screen', (
    tester,
  ) async {
    await pump(tester, basket());
    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('history active=true'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(historyBuilds.last, isFalse);

    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();
    // Same State: the tap counted before the round trip is still there.
    expect(find.text('history active=true taps=1'), findsOneWidget);
  });

  testWidgets('the history is not on screen while another shell tab is', (
    tester,
  ) async {
    await pump(tester, basket());
    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();

    await pump(tester, basket(active: false));

    expect(find.textContaining('history active=false'), findsOneWidget);
  });

  testWidgets('an empty cart can go back to shopping', (tester) async {
    await pump(tester, basket());

    await tester.tap(find.text('the cart'));

    expect(browses, 1);
  });

  testWidgets('the Cart tab of the bottom nav shows the item count', (
    tester,
  ) async {
    await pump(
      tester,
      ShellBottomNav(
        index: ShellBottomNav.cartTab,
        cartIconKey: GlobalKey(),
        onTap: (_) {},
      ),
    );

    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
