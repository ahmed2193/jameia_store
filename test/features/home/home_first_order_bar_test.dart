// The first-order free-delivery bar on the tab bar, wired to the real cart
// and home cubits the way the shell wires it (the home tab relays its
// answer to the bar): a customer due the gift sees it (in place of the
// minimum-order bar) — never on the Cart tab — a tap opens the welcome-gift
// GIF popup (the held frame under reduced motion), the ring closes it, and
// a placed order takes the bar away.
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:hero_mart/src/features/home/presentation/cubit/first_order_bar_cubit.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_cart_bar.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_first_order_banner.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_first_order_bar.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_first_order_relay.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_min_order_bar.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_popup_close_ring.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_welcome_gift_art.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_welcome_popup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'home_test_fakes.dart';

/// A guest in a zone with a 2.500 minimum, the gift on.
const HomeBootstrap _guestGift = HomeBootstrap(
  firstOrderFreeDelivery: true,
  delivery: HomeDelivery(minOrderFils: 2500),
);

const String _barLabel = 'Free delivery on your first order. Show details';

void main() {
  late FakeCartRepository cartRepository;
  late FakeHomeRepository homeRepository;
  late CartCubit cartCubit;
  late HomeCubit homeCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository();
    homeRepository = FakeHomeRepository()..bootstrap = const Right(_guestGift);
  });

  tearDown(() async {
    await cartCubit.close();
    await homeCubit.close();
    await cartRepository.dispose();
  });

  /// The GIF keeps animating once the popup is up: timed frames, never a
  /// settle.
  Future<void> frames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The cubits are built and loaded on the real event loop (see
  /// home_cart_bar_test.dart); the gift popup pops through the router and
  /// picks its GIF by `context.locale`, so both are real. As in the shell:
  /// the home tab (its relay) feeds the bar on the tab bar through the
  /// shared [FirstOrderBarCubit]; [here] is false on the Cart tab. With
  /// [loadedFirst] the home cubit already knows when the tab mounts (the
  /// read the splash started).
  Future<void> pumpBars(
    WidgetTester tester, {
    bool here = true,
    bool loadedFirst = false,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: const HomeFirstOrderRelay(child: SizedBox()),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HomeCartBar(),
                HomeFirstOrderBar(here: here),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
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
      if (loadedFirst) {
        await homeCubit.load();
        await Future<void>.delayed(Duration.zero);
      }
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<HomeCubit>.value(value: homeCubit),
            BlocProvider<FirstOrderBarCubit>(
              create: (_) => FirstOrderBarCubit(),
            ),
          ],
          child: EasyLocalization(
            supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp.router(
                routerConfig: router,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
              ),
            ),
          ),
        ),
      );
      if (!loadedFirst) await homeCubit.load();
      // Lets the translations, the cart's first snapshot and the gift check
      // arrive.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  /// The image the gift card shows.
  String shownArt(WidgetTester tester) {
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(HomeWelcomeGiftArt),
        matching: find.byType(Image),
      ),
    );
    return (image.image as AssetImage).assetName;
  }

  testWidgets('a customer due the gift sees its bar, not the minimum bar', (
    tester,
  ) async {
    await pumpBars(tester);

    expect(find.byType(HomeFirstOrderBanner), findsOneWidget);
    expect(find.bySemanticsLabel(_barLabel), findsOneWidget);
    expect(find.text('Free delivery'), findsOneWidget);
    expect(
      find.textContaining('on your first order', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(HomeMinOrderBar), findsNothing);
  });

  testWidgets('no gift: the minimum bar stands alone', (tester) async {
    homeRepository.bootstrap = const Right(
      HomeBootstrap(delivery: HomeDelivery(minOrderFils: 2500)),
    );

    await pumpBars(tester);

    expect(find.byType(HomeFirstOrderBanner), findsNothing);
    expect(find.byType(HomeMinOrderBar), findsOneWidget);
  });

  testWidgets('a tap opens the welcome-gift GIF; the ring closes it', (
    tester,
  ) async {
    await pumpBars(tester);

    await tester.tap(find.byType(HomeFirstOrderBanner));
    await frames(tester);

    expect(find.byType(HomeWelcomePopupView), findsOneWidget);
    expect(shownArt(tester), HomeWelcomeGiftArt.gifFor('en'));

    await tester.tap(find.byType(HomePopupCloseRing));
    await frames(tester);
    expect(find.byType(HomeWelcomePopupView), findsNothing);
    expect(find.byType(HomeFirstOrderBanner), findsOneWidget);
  });

  testWidgets('"Order now" on the card just closes it', (tester) async {
    await pumpBars(tester);

    await tester.tap(find.byType(HomeFirstOrderBanner));
    await frames(tester);
    await tester.tap(find.byType(HomeWelcomeGiftArt));
    await frames(tester);

    expect(find.byType(HomeWelcomePopupView), findsNothing);
    expect(find.byType(HomeFirstOrderBanner), findsOneWidget);
  });

  testWidgets('reduced motion: the card shows its held frame', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpBars(tester);

    await tester.tap(find.byType(HomeFirstOrderBanner));
    await frames(tester, 3);

    expect(shownArt(tester), HomeWelcomeGiftArt.stillFor('en'));
  });

  testWidgets('a placed order sinks the bar; the minimum bar comes back', (
    tester,
  ) async {
    await pumpBars(tester);
    expect(find.byType(HomeFirstOrderBanner), findsOneWidget);

    homeCubit.onOrderPlaced();
    await tester.pumpAndSettle();

    expect(find.byType(HomeFirstOrderBanner), findsNothing);
    expect(find.byType(HomeMinOrderBar), findsOneWidget);
  });

  testWidgets('on the Cart tab the bar stands aside, even when due', (
    tester,
  ) async {
    await pumpBars(tester, here: false);

    expect(find.byType(HomeFirstOrderBanner), findsNothing);
  });

  testWidgets('an answer the home tab already had shows on its first frame', (
    tester,
  ) async {
    await pumpBars(tester, loadedFirst: true);

    expect(homeCubit.state.firstOrderGift, isTrue);
    expect(find.byType(HomeFirstOrderBanner), findsOneWidget);
  });
}
