// The shell places what the router gives it around its tab bar: the scope
// wraps the whole shell (tab bodies AND tab bar, so a tab can share state
// with a bar), and what stands on the tab bar is told which tab is on
// screen as the customer moves between tabs.
import 'package:dartz/dartz.dart' show Right;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/routes/route_args/shell_tabs.dart';
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
import 'package:hero_mart/src/features/shell/presentation/pages/main_shell_page.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_bottom_nav.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_nav_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import '../cart/fake_cart_repository.dart';

const Key _scope = Key('shell-scope');

void main() {
  late FakeCartRepository repository;
  late CartCubit cartCubit;
  late AuthSessionCubit session;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
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
    session = AuthSessionCubit(
      restoreSession: FakeRestoreSessionUseCase(const Right(null)),
      logout: FakeLogoutUseCase(),
      watchExpiry: FakeWatchSessionExpiryUseCase(),
      getCachedCustomer: FakeGetCachedCustomerUseCase(const Right(null)),
      saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
      clearCachedCustomer: FakeClearCachedCustomerUseCase(),
    );
  });

  tearDown(() async {
    await cartCubit.close();
    await session.close();
    await repository.dispose();
  });

  ShellTabs tabs() => ShellTabs(
    home: (_) => const Text('home body'),
    search: (_) => const Text('search body'),
    cart: (_) => const Text('cart body'),
    orderHistory: (_) => const Text('history'),
    mine: (_) => const Text('mine body'),
    scope: (shell) => KeyedSubtree(key: _scope, child: shell),
    tabBarTop: (tab) => Text('on ${tab.name}'),
  );

  Future<void> pumpShell(WidgetTester tester) async {
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
                home: MainShellPage(tabs: tabs()),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('the scope wraps the tab bodies and the tab bar', (tester) async {
    await pumpShell(tester);

    for (final inside in [
      find.text('home body'),
      find.byType(ShellBottomNav),
    ]) {
      expect(
        find.ancestor(of: inside, matching: find.byKey(_scope)),
        findsOneWidget,
      );
    }
  });

  testWidgets('what stands on the tab bar follows the tab, above the bar', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('on home'), findsOneWidget);
    expect(
      tester.getRect(find.text('on home')).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(ShellBottomNav)).top),
    );

    await tester.tap(find.byType(ShellNavItem).at(ShellBottomNav.searchTab));
    await tester.pumpAndSettle();
    expect(find.text('on search'), findsOneWidget);

    await tester.tap(find.byType(ShellNavItem).at(ShellBottomNav.cartTab));
    await tester.pumpAndSettle();
    expect(find.text('on cart'), findsOneWidget);

    await tester.tap(find.byType(ShellNavItem).at(ShellBottomNav.mineTab));
    await tester.pumpAndSettle();
    expect(find.text('on mine'), findsOneWidget);
  });
}
