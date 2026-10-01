// The bar under the home feed, wired to the real cart and home cubits: an
// empty basket is told the store's minimum to start from, and once the basket
// has items the bar is gone — the Cart tab carries the basket from there.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
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
import 'package:hero_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:hero_mart/src/features/home/domain/usecases/check_first_order_welcome_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/compose_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/mark_home_popups_shown_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/select_due_home_popups_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_bootstrap_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_cart_bar.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_min_order_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'home_test_fakes.dart';

const CatalogProductEntity _rice = CatalogProductEntity(
  id: 'p1',
  slug: 'basmati-rice',
  name: 'Basmati rice',
  priceFils: 1000,
  stock: 12,
);

CartSnapshot _basket(CartTotalsEntity totals) => CartSnapshot(
  cart: CartEntity(
    itemCount: 3,
    lines: const [
      CartLineEntity(
        key: 'l1',
        product: _rice,
        quantity: 3,
        unitPriceFils: 1000,
        lineTotalFils: 3000,
      ),
    ],
    totals: totals,
  ),
  isRestored: true,
);

void main() {
  late FakeCartRepository cartRepository;
  late FakeHomeRepository homeRepository;
  late CartCubit cartCubit;
  late HomeCubit homeCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() {
    cartRepository = FakeCartRepository();
    homeRepository = FakeHomeRepository()
      ..bootstrap = const Right(
        HomeBootstrap(delivery: HomeDelivery(minOrderFils: 2500)),
      );
  });

  tearDown(() async {
    await cartCubit.close();
    await homeCubit.close();
    await cartRepository.dispose();
  });

  /// The cubits are built, loaded and closed on the real event loop: built in
  /// the test's fake-async zone, their stream plumbing would wait forever on
  /// microtasks nobody flushes once the test body is over.
  Future<void> pumpBar(WidgetTester tester) async {
    await tester.runAsync(() async {
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
      )..start();
      homeCubit = HomeCubit(
        WatchHomeFeedUseCase(homeRepository),
        const ComposeHomeFeedUseCase(),
        WatchHomeBootstrapUseCase(homeRepository),
        SelectDueHomePopupsUseCase(homeRepository),
        MarkHomePopupsShownUseCase(homeRepository),
        CheckFirstOrderWelcomeUseCase(homeRepository),
      );
      await homeCubit.load();
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<HomeCubit>.value(value: homeCubit),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(),
              bottomNavigationBar: HomeCartBar(),
            ),
          ),
        ),
      );
      // Lets the cart's first snapshot arrive.
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('an empty basket is told the store minimum to start from', (
    tester,
  ) async {
    await pumpBar(tester);

    expect(
      find.text('Start adding KD 2.500 to place your order!'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('About the minimum order'));
    await tester.pump();
    expect(
      find.text('The minimum order for delivery is KD 2.500.'),
      findsOneWidget,
    );
  });

  testWidgets('no known minimum: an empty basket shows no bar', (tester) async {
    homeRepository.bootstrap = const Right(HomeBootstrap.empty);

    await pumpBar(tester);

    expect(find.byType(HomeMinOrderBar), findsNothing);
  });

  testWidgets('a basket under the minimum shows no bar on home', (
    tester,
  ) async {
    cartRepository.snapshot = _basket(
      const CartTotalsEntity(
        subtotalFils: 1000,
        minOrderFils: 2500,
        meetsMinOrder: false,
      ),
    );

    await pumpBar(tester);

    expect(find.byType(HomeMinOrderBar), findsNothing);
    expect(find.textContaining('KD'), findsNothing);
  });

  testWidgets('a basket that can be ordered shows no bar on home', (
    tester,
  ) async {
    cartRepository.snapshot = _basket(
      const CartTotalsEntity(subtotalFils: 3000, minOrderFils: 2500),
    );

    await pumpBar(tester);

    expect(find.byType(HomeMinOrderBar), findsNothing);
    expect(find.text('3 items'), findsNothing);
    expect(find.textContaining('KD'), findsNothing);
  });

  testWidgets('emptying the basket brings the prompt back', (tester) async {
    cartRepository.snapshot = _basket(
      const CartTotalsEntity(subtotalFils: 3000, minOrderFils: 2500),
    );
    await pumpBar(tester);
    expect(find.byType(HomeMinOrderBar), findsNothing);

    await tester.runAsync(() async {
      cartRepository.push(const CartSnapshot(isRestored: true));
      await Future<void>.delayed(Duration.zero);
    });
    // It rises out of the bottom edge rather than popping in.
    await tester.pump();
    await tester.pump(AppMotion.slow ~/ 2);
    final rising = tester
        .widget<SizeTransition>(find.byType(SizeTransition).last)
        .sizeFactor
        .value;
    expect(rising, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();

    expect(
      find.text('Start adding KD 2.500 to place your order!'),
      findsOneWidget,
    );
  });
}
