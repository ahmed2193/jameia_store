// Route-table tests for the GoRouter config (`config/routes/app_router.dart`).
//
// Boots the real service locator (loads the bundled Hero catalog), mounts a
// test app shaped like `HeroApp` (app-global cubits above
// `MaterialApp.router`) over a FRESH router built from the real `appRoutes`,
// then, for every route path (with a representative `extra`), pushes it and
// asserts the expected page type is on screen with no thrown exception.
// Also covers: unknown paths -> PlaceholderPage, the initial location, an
// awaited push resolving with the popped value, and push / pushReplacement /
// go back-stack semantics.
//
// Network thumbnails (HeroImage) resolve to placeholders under test — that is
// expected and must not throw.

import 'dart:convert';

import 'package:dartz/dartz.dart' show Right;
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/app_router.dart';
import 'package:hero_mart/src/config/routes/placeholder_page.dart';
import 'package:hero_mart/src/config/routes/route_args/assistant_chat_args.dart';
import 'package:hero_mart/src/config/routes/route_args/category_args.dart';
import 'package:hero_mart/src/config/routes/route_args/pdp_image_viewer_args.dart';
import 'package:hero_mart/src/config/routes/route_args/product_detail_args.dart';
import 'package:hero_mart/src/config/routes/route_args/product_listing_args.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/data/hero_repository.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/domain/entities/hero_address_entity.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/setting_cubit.dart';
import 'package:hero_mart/src/features/account/presentation/pages/loyalty_page.dart';
import 'package:hero_mart/src/features/account/presentation/pages/loyalty_rewards_page.dart';
import 'package:hero_mart/src/features/account/presentation/pages/mine_about_page.dart';
import 'package:hero_mart/src/features/account/presentation/pages/mine_delivery_code_page.dart';
import 'package:hero_mart/src/features/account/presentation/pages/mine_page.dart';
import 'package:hero_mart/src/features/account/presentation/pages/mine_settings_page.dart';
import 'package:hero_mart/src/features/account/presentation/pages/profile_edit_page.dart';
import 'package:hero_mart/src/features/account/presentation/pages/wallet_page.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_book.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/pages/address_edit_page.dart';
import 'package:hero_mart/src/features/address/presentation/pages/address_list_page.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/pages/assistant_chat_page.dart';
import 'package:hero_mart/src/features/assistant/presentation/pages/assistant_history_page.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/pages/login_page.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/pages/cart_preview_page.dart';
import 'package:hero_mart/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:hero_mart/src/features/checkout/presentation/pages/checkout_vouchers_page.dart';
import 'package:hero_mart/src/features/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'package:hero_mart/src/features/connectivity/presentation/widgets/connectivity_banner_host.dart';
import 'package:hero_mart/src/features/coupons/presentation/pages/history_coupons_page.dart';
import 'package:hero_mart/src/features/coupons/presentation/pages/my_coupons_page.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:hero_mart/src/features/marketing/domain/entities/content_page_entity.dart';
import 'package:hero_mart/src/features/marketing/presentation/pages/content_page.dart';
import 'package:hero_mart/src/features/marketing/presentation/pages/offers_page.dart';
import 'package:hero_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:hero_mart/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_invoice_page.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_review_page.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/orders_page.dart';
import 'package:hero_mart/src/features/product_details/presentation/pages/pdp_image_viewer_page.dart';
import 'package:hero_mart/src/features/product_details/presentation/pages/product_detail_page.dart';
import 'package:hero_mart/src/features/recipes/presentation/pages/recipe_detail_page.dart';
import 'package:hero_mart/src/features/recipes/presentation/pages/recipes_page.dart';
import 'package:hero_mart/src/features/search/presentation/pages/search_page.dart';
import 'package:hero_mart/src/features/shell/presentation/pages/main_shell_page.dart';
import 'package:hero_mart/src/features/shop/presentation/pages/brands_page.dart';
import 'package:hero_mart/src/features/shop/presentation/pages/categories_page.dart';
import 'package:hero_mart/src/features/shop/presentation/pages/category_page.dart';
import 'package:hero_mart/src/features/shop/presentation/pages/product_listing_page.dart';
import 'package:hero_mart/src/features/splash/presentation/pages/splash_page.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'package:hero_mart/src/features/store_mode/presentation/pages/pro_membership_page.dart';
import 'package:hero_mart/src/features/support/presentation/pages/customer_service_page.dart';
import 'package:hero_mart/src/features/support/presentation/pages/customer_service_question_page.dart';
import 'package:hero_mart/src/features/support/presentation/pages/im_chat_page.dart';

import 'features/address/address_test_fakes.dart';
import 'core/network/network_test_fakes.dart';

/// One row of the route table: push [path] with the [extra] built from the
/// loaded catalogue and expect [pageType] on top. [verify] optionally checks
/// that the arguments reached the page with the old onGenerateRoute semantics.
class _RouteCase {
  const _RouteCase(
    this.path,
    this.pageType, {
    this.note = '',
    this.extra,
    this.verify,
  });

  final String path;
  final Type pageType;
  final String note;

  final Object? Function(HeroRepository repo)? extra;
  final void Function(WidgetTester tester, Object? extra)? verify;

  String get label => '$path -> $pageType${note.isEmpty ? '' : ' ($note)'}';
}

T _page<T extends Widget>(WidgetTester tester) =>
    tester.widget<T>(find.byType(T).last);

/// Every route path in `Routes` that the router serves, with representative
/// extras (and a few fallback-default checks).
final List<_RouteCase> _routeCases = <_RouteCase>[
  const _RouteCase(Routes.splash, SplashPage),
  const _RouteCase(Routes.shell, MainShellPage),
  const _RouteCase(Routes.home, MainShellPage),
  const _RouteCase(Routes.search, SearchPage),
  _RouteCase(
    Routes.searchShop,
    ProductListingPage,
    note: 'search results are a product listing scoped by the text',
    extra: (_) => ' milk ',
    verify: (t, _) => expect(
      _page<ProductListingPage>(t).args.query,
      const CatalogProductQuery(search: 'milk'),
    ),
  ),
  const _RouteCase(
    Routes.searchShop,
    PlaceholderPage,
    note: 'missing search text extra',
  ),
  const _RouteCase(Routes.orders, OrdersPage),
  const _RouteCase(Routes.mine, MinePage),
  const _RouteCase(Routes.categories, CategoriesPage),
  _RouteCase(
    Routes.category,
    CategoryPage,
    extra: (_) => const CategoryArgs(slug: 'fresh-food', name: 'Fresh Food'),
    verify: (t, extra) => expect(_page<CategoryPage>(t).args, same(extra)),
  ),
  const _RouteCase(
    Routes.category,
    PlaceholderPage,
    note: 'missing CategoryArgs extra',
  ),
  _RouteCase(
    Routes.productListing,
    ProductListingPage,
    extra: (_) => ProductListingArgs.brand(slug: 'almarai', title: 'Almarai'),
    verify: (t, extra) =>
        expect(_page<ProductListingPage>(t).args, same(extra)),
  ),
  const _RouteCase(
    Routes.productListing,
    PlaceholderPage,
    note: 'missing ProductListingArgs extra',
  ),
  const _RouteCase(
    Routes.shopFavorites,
    PlaceholderPage,
    note: 'unbuilt: wishlist API not integrated',
  ),
  const _RouteCase(Routes.cartPreview, CartPreviewPage),
  const _RouteCase(Routes.checkout, CheckoutPage),
  _RouteCase(
    Routes.checkoutVouchers,
    CheckoutVouchersPage,
    note: 'the serving branch travels as a String extra',
    extra: (_) => 'b1',
    verify: (t, extra) =>
        expect(_page<CheckoutVouchersPage>(t).branchId, extra),
  ),
  _RouteCase(
    Routes.checkoutVouchers,
    CheckoutVouchersPage,
    note: 'no branch known yet',
    verify: (t, _) => expect(_page<CheckoutVouchersPage>(t).branchId, isNull),
  ),
  _RouteCase(
    Routes.productDetail,
    ProductDetailPage,
    extra: (_) => const ProductDetailArgs(slug: 'basmati-rice-5kg'),
    verify: (t, extra) => expect(_page<ProductDetailPage>(t).args, same(extra)),
  ),
  const _RouteCase(
    Routes.productDetail,
    PlaceholderPage,
    note: 'missing ProductDetailArgs extra',
  ),
  _RouteCase(
    Routes.productDetail,
    PlaceholderPage,
    note: 'an offline catalogue DTO is no longer a valid extra',
    extra: (repo) => repo.shops.first,
  ),
  _RouteCase(
    Routes.pdpImageViewer,
    PdpImageViewerPage,
    extra: (_) => const PdpImageViewerArgs(
      images: <String>['a', 'b'],
      initialIndex: 1,
      productSlug: 'milk',
    ),
    verify: (t, _) {
      final viewer = _page<PdpImageViewerPage>(t);
      expect(viewer.images, <String>['a', 'b']);
      expect(viewer.initialIndex, 1);
      expect(viewer.productSlug, 'milk');
    },
  ),
  _RouteCase(
    Routes.orderTracking,
    OrderTrackingPage,
    extra: (_) => 'o2',
    verify: (t, extra) => expect(_page<OrderTrackingPage>(t).orderId, extra),
  ),

  const _RouteCase(
    Routes.orderTracking,
    PlaceholderPage,
    note: 'no order id extra',
  ),
  _RouteCase(
    Routes.orderReview,
    OrderReviewPage,
    extra: (_) => 'o1',
    verify: (t, extra) => expect(_page<OrderReviewPage>(t).orderId, extra),
  ),
  _RouteCase(
    Routes.orderInvoice,
    OrderInvoicePage,
    extra: (_) => 'o1',
    verify: (t, extra) => expect(_page<OrderInvoicePage>(t).orderId, extra),
  ),
  const _RouteCase(Routes.addressList, AddressListPage),
  _RouteCase(
    Routes.addressEdit,
    AddressEditPage,
    note: 'new address',
    verify: (t, _) => expect(_page<AddressEditPage>(t).address, isNull),
  ),
  _RouteCase(
    Routes.addressEdit,
    AddressEditPage,
    note: 'edit an existing address entity',
    extra: (_) => const HeroAddressEntity(
      id: 'aaaaaaaaaaaaaaaaaaaaaaa1',
      label: 'Home',
      city: 'Salmiya',
      block: '7',
      street: '22',
      building: '5',
      phone: '+96550001122',
      location: GeoPointEntity(lat: 29.33, lng: 48.07),
    ),
    verify: (t, extra) =>
        expect(_page<AddressEditPage>(t).address, same(extra)),
  ),
  _RouteCase(
    Routes.addressEdit,
    AddressEditPage,
    note: 'a non-entity extra falls back to a new address',
    extra: (_) => 42,
    verify: (t, _) => expect(_page<AddressEditPage>(t).address, isNull),
  ),
  const _RouteCase(Routes.myCoupons, MyCouponsPage),
  const _RouteCase(Routes.historyCoupons, HistoryCouponsPage),
  const _RouteCase(Routes.mineSettings, MineSettingsPage),
  const _RouteCase(Routes.mineAbout, MineAboutPage),
  const _RouteCase(Routes.mineDeliveryCode, MineDeliveryCodePage),
  const _RouteCase(Routes.profileEdit, ProfileEditPage),
  const _RouteCase(Routes.wallet, WalletPage),
  const _RouteCase(Routes.loyalty, LoyaltyPage),
  const _RouteCase(Routes.loyaltyRewards, LoyaltyRewardsPage),
  const _RouteCase(Routes.notifications, NotificationsPage),
  const _RouteCase(Routes.assistant, AssistantChatPage, note: 'new chat'),
  _RouteCase(
    Routes.assistant,
    AssistantChatPage,
    note: 'past conversation',
    extra: (_) => const AssistantChatArgs(conversationId: 'c1'),
    verify: (t, _) => expect(_page<AssistantChatPage>(t).conversationId, 'c1'),
  ),
  const _RouteCase(Routes.assistantHistory, AssistantHistoryPage),
  const _RouteCase(Routes.customerService, CustomerServicePage),
  _RouteCase(
    Routes.customerServiceQuestion,
    CustomerServiceQuestionPage,
    extra: (_) => 'refund',
    verify: (t, extra) =>
        expect(_page<CustomerServiceQuestionPage>(t).arg, extra),
  ),
  _RouteCase(Routes.imChat, ImChatPage, extra: (_) => 'o1'),
  const _RouteCase(Routes.offers, OffersPage),
  _RouteCase(
    Routes.contentPage,
    ContentPage,
    extra: (_) => 'about',
    verify: (t, _) => expect(_page<ContentPage>(t).kind, ContentPageKind.about),
  ),
  _RouteCase(
    Routes.contentPage,
    PlaceholderPage,
    note: 'a slug the backend does not serve',
    extra: (_) => 'careers',
  ),
  const _RouteCase(Routes.recipes, RecipesPage),
  _RouteCase(
    Routes.recipe,
    RecipeDetailPage,
    extra: (_) => 'machboos',
    verify: (t, extra) => expect(_page<RecipeDetailPage>(t).slug, extra),
  ),
  const _RouteCase(
    Routes.recipe,
    PlaceholderPage,
    note: 'missing recipe slug extra',
  ),
  const _RouteCase(Routes.proMembership, ProMembershipPage),
  const _RouteCase(Routes.brands, BrandsPage),
  const _RouteCase(
    Routes.inviteFriends,
    PlaceholderPage,
    note: 'no referral backend',
  ),
  const _RouteCase(Routes.login, LoginPage),
];

/// A trivially cheap base page every case is pushed on top of, so each test
/// exercises `push` over an existing stack.
const String _baseLocation = Routes.inviteFriends;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HeroRepository repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    registerFakeNetworkInfo();
    await setupServiceLocator();
    repo = sl<HeroRepository>();

    // Pre-load English into easy_localization's global singleton so `.tr()`
    // resolves without the async delegate load (see shop_page_test.dart).
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  /// Mounts a `HeroApp`-shaped tree (EasyLocalization for `context.locale`,
  /// the app-global cubits, MaterialApp.router) over a fresh router built from
  /// the real route table.
  Future<GoRouter> pumpRouterApp(
    WidgetTester tester, {
    String initialLocation = _baseLocation,
  }) async {
    final router = buildAppRouter(
      initialLocation: initialLocation,
      rootNavigatorKey: GlobalKey<NavigatorState>(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
            BlocProvider<LocalizationCubit>(
              create: (_) => sl<LocalizationCubit>(),
            ),
            BlocProvider<SettingCubit>(create: (_) => SettingCubit()),
            // Signed-out + idle: MinePage / ProfileEditPage / the home bell
            // read these app-global cubits at build time.
            BlocProvider<AuthSessionCubit>(
              create: (_) => sl<AuthSessionCubit>(),
            ),
            BlocProvider<UnreadNotificationsCubit>(
              create: (_) => sl<UnreadNotificationsCubit>(),
            ),
            // Never loaded: status unknown, so the home disc and the Mine
            // cell stay hidden and nothing reaches the network.
            BlocProvider<AssistantAvailabilityCubit>(
              create: (_) => sl<AssistantAvailabilityCubit>(),
            ),
            // Idle (never started) over fakes: the address pages read it at
            // build time and the list's first sync never touches the network.
            // Over the registered FakeNetworkInfo (online): nothing probes.
            BlocProvider<ConnectivityCubit>(
              create: (_) => sl<ConnectivityCubit>()..start(),
            ),
            // Never started: the Pro standing is unknown, so no member tag,
            // Pro banner or Pro chip shows and nothing reaches the network.
            BlocProvider<ProStatusCubit>(create: (_) => sl<ProStatusCubit>()),
            BlocProvider<AddressBookCubit>(
              create: (_) => AddressBookCubit(
                getCached: FakeGetCachedAddressesUseCase(),
                getAddresses: FakeGetAddressesUseCase(
                  const Right(AddressBook.empty),
                ),
                updateAddress: FakeUpdateAddressUseCase(
                  Right(const HeroAddressEntity(id: 'a1', label: 'Home')),
                ),
                deleteAddress: FakeDeleteAddressUseCase(),
                saveCache: FakeSaveCachedAddressesUseCase(),
                clearCache: FakeClearCachedAddressesUseCase(),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            // As in HeroApp: the connection banner above every route.
            builder: (context, child) => ConnectivityBannerHost(
              routeChanges: router.routerDelegate,
              isOnSplash: () => false,
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  /// Bounded pumps past the 300ms page transition (network image / carousel
  /// timers never quiesce, so no pumpAndSettle).
  Future<void> settleTransition(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Unmounts the tree and advances the clock so page-owned timers (debounces,
  /// countdowns, splash failsafe) are cancelled or flushed before the test ends.
  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  // The top-most match (imperative pushes included).
  String currentPath(GoRouter router) => router.state.uri.path;

  group('route table', () {
    for (final routeCase in _routeCases) {
      testWidgets(routeCase.label, (tester) async {
        final extra = routeCase.extra?.call(repo);
        final router = await pumpRouterApp(tester);

        router.push(routeCase.path, extra: extra);
        await settleTransition(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: '${routeCase.path} threw while building',
        );
        expect(
          find.byType(routeCase.pageType),
          findsWidgets,
          reason: '${routeCase.path} should show ${routeCase.pageType}',
        );
        expect(currentPath(router), routeCase.path);
        routeCase.verify?.call(tester, extra);

        await teardownApp(tester);
      });
    }
  });

  testWidgets('initial location is the splash page', (tester) async {
    final router = await pumpRouterApp(tester, initialLocation: Routes.splash);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SplashPage), findsOneWidget);
    expect(router.canPop(), isFalse);

    await teardownApp(tester);
  });

  testWidgets('unknown path lands on PlaceholderPage titled from the path', (
    tester,
  ) async {
    final router = await pumpRouterApp(tester);

    router.push('/does-not-exist');
    await settleTransition(tester);

    expect(tester.takeException(), isNull);
    expect(_page<PlaceholderPage>(tester).title, 'does not exist');
    expect(router.canPop(), isTrue);

    await teardownApp(tester);
  });

  testWidgets('unknown initial location renders the error PlaceholderPage', (
    tester,
  ) async {
    await pumpRouterApp(tester, initialLocation: '/nowhere-at-all');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(_page<PlaceholderPage>(tester).title, 'nowhere at all');

    await teardownApp(tester);
  });

  testWidgets('awaited push resolves with the value the page pops', (
    tester,
  ) async {
    final router = await pumpRouterApp(tester);

    int? returned;
    var completed = false;
    router
        .push<int>(
          Routes.pdpImageViewer,
          extra: const PdpImageViewerArgs(
            images: <String>['a', 'b', 'c'],
            initialIndex: 2,
            productSlug: 'milk',
          ),
        )
        .then((value) {
          returned = value;
          completed = true;
        });
    await settleTransition(tester);
    expect(find.byType(PdpImageViewerPage), findsOneWidget);

    // System back: the viewer's PopScope intercepts it and pops with its
    // current page index (context.pop(_index)).
    await tester.binding.handlePopRoute();
    await settleTransition(tester);

    expect(tester.takeException(), isNull);
    expect(completed, isTrue);
    expect(returned, 2);
    expect(find.byType(PdpImageViewerPage), findsNothing);
    expect(currentPath(router), _baseLocation);

    await teardownApp(tester);
  });

  testWidgets('GoRouter.pop(result) completes the push future', (tester) async {
    final router = await pumpRouterApp(tester);

    Object? returned;
    router
        .push<Object?>(Routes.shopFavorites)
        .then((value) => returned = value);
    await settleTransition(tester);

    router.pop('picked');
    await settleTransition(tester);

    expect(tester.takeException(), isNull);
    expect(returned, 'picked');
    expect(currentPath(router), _baseLocation);

    await teardownApp(tester);
  });

  testWidgets('pushReplacement swaps the top page and keeps the stack below', (
    tester,
  ) async {
    final router = await pumpRouterApp(tester);

    router.push(Routes.mineAbout);
    await settleTransition(tester);
    router.pushReplacement(Routes.offers);
    await settleTransition(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(OffersPage), findsOneWidget);
    expect(find.byType(MineAboutPage), findsNothing);
    expect(router.canPop(), isTrue);

    router.pop();
    await settleTransition(tester);

    expect(find.byType(OffersPage), findsNothing);
    expect(currentPath(router), _baseLocation);

    await teardownApp(tester);
  });

  testWidgets('go replaces the whole stack', (tester) async {
    final router = await pumpRouterApp(tester);

    router.push(Routes.mineAbout);
    await settleTransition(tester);
    router.go(Routes.login);
    await settleTransition(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MineAboutPage), findsNothing);
    expect(router.canPop(), isFalse);

    await teardownApp(tester);
  });
}
