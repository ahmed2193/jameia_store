// The checkout page as the router shows it (G5): its cubits come from the
// real container shape (`sl<CheckoutCubit>()` …) over scripted fakes, the
// app-global cubits sit above the app. Pins the page's buckets (the rail
// settles first, signed-out, emptied basket), its listeners (placed, a
// refused order, the payment switches it makes and announces, a dropped
// coupon / express / window) and the savings hint's life on the page.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/navigation/hero_shared_axis_page.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/core/widgets/app_loader.dart';
import 'package:hero_mart/src/core/widgets/hero_state_view.dart';
import 'package:hero_mart/src/core/widgets/hero_submit_button.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_offers_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_rail_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_state.dart';
import 'package:hero_mart/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_body.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_hint_bubble.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_order_bar.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_ui_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';
import 'fake_checkout_repository.dart';

/// Counts the session restores (the page re-reads the wallet and points).
class _CountingRestore extends FakeRestoreSessionUseCase {
  _CountingRestore(super.result);

  int calls = 0;

  @override
  Future<Either<Failure, AuthCustomerEntity?>> call(NoParams params) {
    calls++;
    return super.call(params);
  }
}

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late FakeCheckoutRepository checkoutRepository;
  late FakeCheckoutCatalogRepository catalog;
  late _CountingRestore restore;
  late AuthSessionCubit session;
  late AddressBookCubit addressBook;
  CheckoutCubit? checkout;

  const rice = CartLineEntity(
    key: 'l1',
    product: testProduct,
    quantity: 2,
    unitPriceFils: 600,
    lineTotalFils: 1200,
  );

  /// Rice on sale: 0.300 off each of its 2 pieces.
  const riceOnSale = CartLineEntity(
    key: 'l1',
    product: testProduct,
    quantity: 2,
    unitPriceFils: 600,
    compareAtFils: 900,
    lineTotalFils: 1200,
  );
  const oil = CartLineEntity(
    key: 'l2',
    product: otherProduct,
    quantity: 1,
    unitPriceFils: 900,
    lineTotalFils: 900,
  );

  /// 2.100 of goods + the 0.500 delivery fee = 2.600.
  CartSnapshot snapshot({
    List<CartLineEntity> lines = const [rice, oil],
    int subtotalFils = 2100,
    CartCouponEntity? coupon,
    int couponDiscountFils = 0,
    bool expressSelected = false,
    CartAction cause = CartAction.none,
  }) => CartSnapshot(
    cause: cause,
    cart: CartEntity(
      itemCount: 3,
      lines: lines,
      coupon: coupon,
      expressOffered: true,
      expressSelected: expressSelected,
      totals: CartTotalsEntity(
        subtotalFils: subtotalFils,
        couponDiscountFils: couponDiscountFils,
        discountFils: couponDiscountFils,
        deliveryFeeFils: 500,
        baseDeliveryFeeFils: 500,
        totalFils: subtotalFils - couponDiscountFils + 500,
      ),
    ),
    isRestored: true,
  );

  AuthCustomerEntity customer({int walletFils = 0}) => AuthCustomerEntity(
    id: 'c1',
    phone: '+96550000000',
    walletFils: walletFils,
  );

  /// Signs [signedIn] in; the page's restores confirm the same customer.
  void signIn(AuthCustomerEntity signedIn) {
    restore.result = Right(signedIn);
    session.signedIn(signedIn);
  }

  void register<T extends Object>(T Function() factory) {
    if (sl.isRegistered<T>()) sl.unregister<T>();
    sl.registerFactory<T>(factory);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()..snapshot = snapshot();
    cartCubit = buildCartCubit(cartRepository);
    checkoutRepository = FakeCheckoutRepository();
    catalog = FakeCheckoutCatalogRepository();
    restore = _CountingRestore(const Right(null));
    session = AuthSessionCubit(
      restoreSession: restore,
      logout: FakeLogoutUseCase(),
      watchExpiry: FakeWatchSessionExpiryUseCase(),
      getCachedCustomer: FakeGetCachedCustomerUseCase(),
      saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
      clearCachedCustomer: FakeClearCachedCustomerUseCase(),
    );
    addressBook = buildAddressBookCubit();
    checkout = null;
    // The page resolves its cubits through the real container; only what
    // is behind them is faked.
    register<CheckoutCubit>(
      () => checkout = buildCheckoutCubit(checkoutRepository),
    );
    register<CheckoutRailCubit>(() => buildRailCubit(catalog));
    register<CheckoutOffersCubit>(() => buildOffersCubit(catalog));
  });

  tearDown(() async {
    await cartCubit.close();
    await session.close();
    await addressBook.close();
    await cartRepository.dispose();
  });

  /// The app over a router whose home is a stub; the checkout is the first
  /// page, or [pushed] over the (settled) home — so it can pop, and its
  /// route slides in as in the app. Returns the router; the checkout is not
  /// settled yet.
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    bool pushed = false,
    Size size = const Size(480, 2400),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: pushed ? '/' : Routes.checkout,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: Routes.checkout,
          // The app's transition (a `builder:` page would not animate).
          pageBuilder: (_, state) => HeroSharedAxisPage<Object?>(
            key: state.pageKey,
            name: state.uri.path,
            child: const CheckoutPage(),
          ),
        ),
        GoRoute(
          path: Routes.orderTracking,
          builder: (_, state) =>
              Scaffold(body: Text('tracking:${state.extra}')),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [checkoutEn, checkoutAr],
          path: 'assets/i18n',
          fallbackLocale: checkoutEn,
          startLocale: checkoutEn,
          saveLocale: false,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CartCubit>.value(value: cartCubit),
              BlocProvider<AuthSessionCubit>.value(value: session),
              BlocProvider<AddressBookCubit>.value(value: addressBook),
            ],
            child: Builder(
              builder: (context) => MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      // A language file's first load takes a few real event-loop turns.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    if (pushed) {
      await tester.pumpAndSettle();
      unawaited(router.push(Routes.checkout));
    }
    return router;
  }

  /// The checkout, first page, settled.
  Future<GoRouter> pumpPage(WidgetTester tester) async {
    final router = await pumpApp(tester);
    await tester.pumpAndSettle();
    return router;
  }

  /// Pushes a cart snapshot the way the repository stream delivers it.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  CheckoutUiController uiOf(WidgetTester tester) =>
      tester.element(find.byType(CheckoutBody)).read<CheckoutUiController>();

  Finder snack(String text) =>
      find.descendant(of: find.byType(SnackBar), matching: find.text(text));

  Future<void> tapPlaceOrder(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(CheckoutPlaceOrderBar),
        matching: find.byType(HeroSubmitButton),
      ),
    );
    await tester.pump();
  }

  group('buckets', () {
    testWidgets('the content waits for the rail to settle', (tester) async {
      final gate = catalog.railGate = Completer<void>();
      await pumpApp(tester);
      await tester.pump();
      await tester.pump();

      expect(checkout?.state.status, CheckoutStatus.ready);
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.byType(CheckoutBody), findsNothing);

      await tester.runAsync(() async {
        gate.complete();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();

      expect(find.byType(CheckoutBody), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('one scroll view under a title naming the store and branch', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Hero · Salmiya'), findsOneWidget);
    });

    testWidgets('a 401 on the destination shows sign-in, not a redirect', (
      tester,
    ) async {
      checkoutRepository.selectFailure = const UnauthorizedFailure();
      final router = await pumpPage(tester);

      expect(checkout?.state.requiresSignIn, isTrue);
      expect(find.byType(HeroStateView), findsOneWidget);
      expect(find.text('Sign in to place your order'), findsOneWidget);
      expect(find.byType(CheckoutBody), findsNothing);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.checkout,
      );
    });

    testWidgets('an emptied basket offers to start shopping, which goes back', (
      tester,
    ) async {
      await pumpApp(tester, pushed: true);
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutBody), findsOneWidget);

      await emit(
        tester,
        const CartSnapshot(cart: CartEntity.empty, isRestored: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty'), findsOneWidget);
      await tester.tap(find.text('Start shopping'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('placing', () {
    testWidgets(
      'placed: re-reads the session for a COD order too, goes to tracking, '
      'no hint, nothing left ticking',
      (tester) async {
        signIn(customer());
        cartRepository.push(snapshot(lines: const [riceOnSale, oil]));
        final router = await pumpPage(tester);
        expect(restore.calls, 1); // on open
        expect(find.byType(CheckoutHintBubble), findsOneWidget);

        await tapPlaceOrder(tester);
        await tester.pump();

        expect(checkout?.state.status, CheckoutStatus.placed);
        expect(checkoutRepository.calls, contains('place:cod'));
        expect(restore.calls, 2);
        expect(find.byType(CheckoutHintBubble), findsNothing);

        // The order took the cart with it while the page is still leaving.
        await emit(
          tester,
          const CartSnapshot(cart: CartEntity.empty, isRestored: true),
        );
        await tester.pump(const Duration(seconds: 10));

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          Routes.orderTracking,
        );
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      'a refused order re-reads the cart and the wallet, and puts the hint away',
      (tester) async {
        signIn(customer(walletFils: 5000));
        checkoutRepository.placeFailure = const ServerFailure('Out of slots');
        cartRepository.push(snapshot(lines: const [riceOnSale, oil]));
        await pumpPage(tester);
        checkout!.setPaymentMethod(OrderPaymentMethod.wallet);
        await tester.pump();
        final fetches = cartRepository.calls.where((c) => c == 'fetch').length;
        final restores = restore.calls;

        await tapPlaceOrder(tester);
        await tester.pumpAndSettle();

        expect(checkoutRepository.calls, contains('place:wallet'));
        expect(snack('Out of slots'), findsOneWidget);
        expect(
          cartRepository.calls.where((c) => c == 'fetch').length,
          fetches + 1,
        );
        expect(restore.calls, restores + 1);
        expect(uiOf(tester).hintDismissed.value, isTrue);
        expect(find.byType(CheckoutHintBubble), findsNothing);
      },
    );
  });

  group('payment switches', () {
    testWidgets(
      'a store without cash on delivery pays with a covering wallet',
      (tester) async {
        checkoutRepository.rules = const CheckoutStoreRules(
          storeName: 'Hero',
          codEnabled: false,
        );
        signIn(customer(walletFils: 5000));
        await pumpPage(tester);

        expect(checkout?.state.draft.paymentMethod, OrderPaymentMethod.wallet);
      },
    );

    testWidgets('cash on delivery stays for a guest (no wallet to move to)', (
      tester,
    ) async {
      checkoutRepository.rules = const CheckoutStoreRules(codEnabled: false);
      await pumpPage(tester);

      expect(checkout?.state.draft.paymentMethod, OrderPaymentMethod.cod);
      expect(restore.calls, 0); // nothing to re-read for a guest
    });

    testWidgets(
      'a total past the wallet falls back to cash on delivery, and says so',
      (tester) async {
        signIn(customer(walletFils: 3000));
        await pumpPage(tester);
        checkout!.setPaymentMethod(OrderPaymentMethod.wallet);
        await tester.pump();

        await emit(tester, snapshot(subtotalFils: 3000)); // 3.500
        await tester.pump();

        expect(checkout?.state.draft.paymentMethod, OrderPaymentMethod.cod);
        expect(
          snack(
            'Your wallet no longer covers this order, so we switched to cash '
            'on delivery',
          ),
          findsOneWidget,
        );
        expect(uiOf(tester).paymentBumps.value, 1);
      },
    );

    testWidgets('without cash on delivery a short wallet stays and blocks', (
      tester,
    ) async {
      checkoutRepository.rules = const CheckoutStoreRules(codEnabled: false);
      signIn(customer(walletFils: 3000));
      await pumpPage(tester);
      expect(checkout?.state.draft.paymentMethod, OrderPaymentMethod.wallet);

      await emit(tester, snapshot(subtotalFils: 3000)); // 3.500
      await tester.pumpAndSettle();

      expect(checkout?.state.draft.paymentMethod, OrderPaymentMethod.wallet);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CheckoutPlaceOrderBar),
          matching: find.text('No payment method is available for this order'),
        ),
        findsOneWidget,
      );
    });
  });

  group('announced changes', () {
    testWidgets('a coupon the server dropped is announced', (tester) async {
      cartRepository.push(
        snapshot(
          coupon: const CartCouponEntity(code: 'SAVE', discountFils: 200),
          couponDiscountFils: 200,
        ),
      );
      await pumpPage(tester);

      await emit(tester, snapshot());
      await tester.pump();

      expect(
        snack('Coupon SAVE no longer applies to this basket'),
        findsOneWidget,
      );
    });

    testWidgets('the customer removing their own coupon is not news', (
      tester,
    ) async {
      cartRepository.push(
        snapshot(
          coupon: const CartCouponEntity(code: 'SAVE', discountFils: 200),
          couponDiscountFils: 200,
        ),
      );
      await pumpPage(tester);

      // "Remove" on Coupons & offers: the call's result comes first (busy
      // back to none), the cart it brought lands after it.
      await tester.runAsync(cartCubit.removeCoupon);
      await tester.pump();
      await emit(tester, snapshot(cause: CartAction.coupon));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the customer switching express off is not news', (
      tester,
    ) async {
      cartRepository.push(snapshot(expressSelected: true));
      await pumpPage(tester);

      await tester.runAsync(() => cartCubit.setExpress(enabled: false));
      await tester.pump();
      await emit(tester, snapshot(cause: CartAction.express));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a pickup order drops express without a word', (tester) async {
      cartRepository.push(snapshot(expressSelected: true));
      await pumpPage(tester);
      expect(checkout?.state.draft.timing, DeliveryTiming.express);

      await tester.runAsync(() => checkout!.selectBranch('b1'));
      await tester.pump();
      // The refreshed cart: select-branch let go of express.
      await emit(tester, snapshot());
      await tester.pump();

      expect(checkout?.state.draft.isPickup, isTrue);
      expect(checkout?.state.draft.timing, DeliveryTiming.asap);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('express the new zone lost goes back to ASAP, with a snack', (
      tester,
    ) async {
      cartRepository.push(snapshot(expressSelected: true));
      await pumpPage(tester);
      expect(checkout?.state.draft.timing, DeliveryTiming.express);

      await emit(tester, snapshot());
      await tester.pump();

      expect(checkout?.state.draft.timing, DeliveryTiming.asap);
      expect(
        snack(
          "Express isn't available for this address, so we switched to as "
          'soon as possible',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a delivery window the new address lost is announced', (
      tester,
    ) async {
      await pumpPage(tester);
      checkout!.setSlot(checkoutRepository.days.first.slots.first);
      checkoutRepository.days = const [];

      await checkout!.selectAddress('a1');
      await tester.pump();

      expect(checkout?.state.draft.timing, DeliveryTiming.asap);
      expect(
        snack(
          "Your delivery window isn't available for this address, so we "
          'switched to as soon as possible',
        ),
        findsOneWidget,
      );
    });
  });

  group('savings hint', () {
    testWidgets('CT-H1: waits for the route to settle, then pops and rests', (
      tester,
    ) async {
      cartRepository.push(snapshot(lines: const [riceOnSale, oil]));
      await pumpApp(tester, pushed: true);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // The route is still sliding in: no bubble yet.
      expect(find.byType(CheckoutBody), findsOneWidget);
      expect(find.byType(CheckoutHintBubble), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(CheckoutHintBubble), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'CT-H2: a scroll the customer makes dismisses it; one the page makes '
      'does not',
      (tester) async {
        cartRepository.push(snapshot(lines: const [riceOnSale, oil]));
        await pumpPage(tester);
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );

        // The page's own scroll (a blocked tap brings a row back).
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(find.byType(CheckoutHintBubble), findsOneWidget);

        // What a drag on the page (or on the rail) sends up.
        UserScrollNotification(
          metrics: scrollable.position.copyWith(),
          context: scrollable.context,
          direction: ScrollDirection.reverse,
        ).dispatch(scrollable.context);
        await tester.pumpAndSettle();
        expect(find.byType(CheckoutHintBubble), findsNothing);

        await emit(
          tester,
          snapshot(
            lines: [riceOnSale.withQuantity(3), oil],
            subtotalFils: 2700,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CheckoutHintBubble), findsNothing);
      },
    );
  });
}
