// A collection, a brand or the "view all" of a home rail opens as a talabat
// collection page: the store's name in the top bar, the tinted hero (heading,
// emoji, line, a flash sale's countdown), category tabs once two or more
// categories have products, the grid without the sort / filter toolbar and
// the "View cart" pill. Search results keep the plain catalogue look.
import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/route_args/product_listing_args.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/motion/fly_to_cart.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/core/widgets/collection_frame.dart';
import 'package:jameia_mart/src/core/widgets/collection_hero.dart';
import 'package:jameia_mart/src/core/widgets/collection_tab_strip.dart';
import 'package:jameia_mart/src/core/widgets/countdown_chip.dart';
import 'package:jameia_mart/src/core/widgets/round_outlined_button.dart';
import 'package:jameia_mart/src/core/widgets/view_cart_pill.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_state.dart';
import 'package:jameia_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:jameia_mart/src/features/language/presentation/cubit/localization_state.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_listing_category_tabs_usecase.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_products_usecase.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/listing_tabs_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/product_listing_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/pages/product_listing_page.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/listing/catalog_app_bar.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/listing/catalog_cart_bar.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/listing/listing_results_count.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/listing/listing_toolbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop_test_fakes.dart';

class _MockCartCubit extends MockCubit<CartState> implements CartCubit {}

class _MockAuthSessionCubit extends MockCubit<AuthSessionState>
    implements AuthSessionCubit {}

class _MockLocalizationCubit extends MockCubit<LocalizationState>
    implements LocalizationCubit {}

/// Answers every page at once: [count] products named after the category
/// scope ("all 0", "ice-cream 3" …), so a re-scoped grid is visible.
class _FakeGetProducts implements GetProductsUseCase {
  _FakeGetProducts({this.count = 6});

  final int count;
  final List<GetProductsParams> requests = [];

  @override
  Future<Either<Failure, CatalogProductsPage>> call(
    GetProductsParams params,
  ) async {
    requests.add(params);
    final scope = params.query.categorySlug ?? 'all';
    return Right(
      CatalogProductsPage(
        products: [
          for (var i = 0; i < count; i++)
            CatalogProductEntity(
              id: '$scope-$i',
              slug: '$scope-$i',
              name: '$scope $i',
              priceFils: 1250,
              stock: 10,
            ),
        ],
        page: 1,
        hasMore: false,
        total: count,
      ),
    );
  }
}

class _FakeTabs implements GetListingCategoryTabsUseCase {
  _FakeTabs(this.reply);

  final Either<Failure, List<CatalogCategoryEntity>> reply;
  int calls = 0;

  @override
  Future<Either<Failure, List<CatalogCategoryEntity>>> call(
    GetListingCategoryTabsParams params,
  ) async {
    calls++;
    return reply;
  }
}

const CatalogCategoryEntity _snacks = CatalogCategoryEntity(
  id: 'c1',
  slug: 'snacks',
  name: 'Snacks & Chocolate',
);
const CatalogCategoryEntity _iceCream = CatalogCategoryEntity(
  id: 'c2',
  slug: 'ice-cream',
  name: 'Ice Cream',
);

/// A full-screen page with its own cart icon over the listing, like the
/// product page: it takes the fly-to-cart flights while it is on top.
class _CoverPage extends StatefulWidget {
  const _CoverPage();

  static const String path = '/cover';
  static final GlobalKey target = GlobalKey();
  static final GlobalKey source = GlobalKey();

  @override
  State<_CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<_CoverPage> {
  @override
  void initState() {
    super.initState();
    FlyToCart.pushTarget(_CoverPage.target);
  }

  @override
  void dispose() {
    FlyToCart.popTarget(_CoverPage.target);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        PositionedDirectional(
          top: 80,
          start: 24,
          child: SizedBox.square(key: _CoverPage.target, dimension: 40),
        ),
        PositionedDirectional(
          top: 360,
          start: 200,
          child: SizedBox.square(key: _CoverPage.source, dimension: 40),
        ),
      ],
    ),
  );
}

const String _heading = 'Best sellers near you';
const String _subtitle = 'Picked by shoppers around you';

ProductListingArgs _bestSellers({DateTime? endsAt}) =>
    ProductListingArgs.collection(
      slug: 'best-sellers',
      title: _heading,
      subtitle: _subtitle,
      emoji: '🔥',
      endsAt: endsAt,
    );

CartState _basket({required int qty, required int subtotalFils}) => CartState(
  isRestored: true,
  cart: CartEntity(
    itemCount: qty,
    lines: [
      CartLineEntity(
        key: 'l1',
        product: const CatalogProductEntity(
          id: 'p1',
          slug: 'rice',
          name: 'Rice',
          priceFils: 1000,
        ),
        quantity: qty,
        unitPriceFils: 1000,
        lineTotalFils: subtotalFils,
      ),
    ],
    totals: CartTotalsEntity(subtotalFils: subtotalFils),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> en;
  late Map<String, dynamic> ar;
  late _FakeGetProducts products;
  late _FakeTabs tabs;
  late _MockCartCubit cart;
  late StreamController<CartState> cartStates;
  late _MockAuthSessionCubit session;
  late _MockLocalizationCubit localization;

  void useLanguage(String code) => Localization.load(
    Locale(code),
    translations: Translations(code == 'ar' ? ar : en),
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    en = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    ar = json.decode(
      await rootBundle.loadString('assets/i18n/ar.json'),
    ) as Map<String, dynamic>;
  });

  /// Registers the page's cubits over the fakes (only what the page
  /// resolves from DI).
  Future<void> register({
    Either<Failure, List<CatalogCategoryEntity>> tabsReply = const Right([
      _snacks,
      _iceCream,
    ]),
    int productCount = 6,
  }) async {
    await sl.reset();
    products = _FakeGetProducts(count: productCount);
    tabs = _FakeTabs(tabsReply);
    sl
      ..registerFactoryParam<ProductListingCubit, CatalogProductQuery, void>(
        (query, _) => ProductListingCubit(
          WatchProductsFromGet(products),
          products,
          NoBrands(),
          query: query,
        ),
      )
      ..registerFactoryParam<ListingTabsCubit, CatalogProductQuery, void>(
        (query, _) => ListingTabsCubit(tabs, query: query),
      );
  }

  setUp(() async {
    useLanguage('en');
    await register();
    cartStates = StreamController<CartState>.broadcast();
    cart = _MockCartCubit();
    whenListen(cart, cartStates.stream, initialState: const CartState());
    session = _MockAuthSessionCubit();
    whenListen(
      session,
      const Stream<AuthSessionState>.empty(),
      initialState: const AuthSessionState(),
    );
    localization = _MockLocalizationCubit();
    whenListen(
      localization,
      const Stream<LocalizationState>.empty(),
      initialState: const LocalizationState(locale: Locale('en')),
    );
  });

  tearDown(() async {
    await cartStates.close();
    await sl.reset();
  });

  /// The listing pushed over a base page (so there is a way back), with the
  /// app-global cubits it reads.
  Future<GoRouter> pumpListing(
    WidgetTester tester,
    ProductListingArgs args, {
    TextDirection direction = TextDirection.ltr,
    bool reducedMotion = false,
  }) async {
    final router = GoRouter(
      initialLocation: '/base',
      routes: [
        GoRoute(
          path: '/base',
          builder: (_, _) => const Scaffold(body: Text('base page')),
        ),
        GoRoute(
          path: Routes.productListing,
          builder: (_, state) =>
              ProductListingPage(args: state.extra! as ProductListingArgs),
        ),
        GoRoute(
          path: Routes.search,
          builder: (_, _) => const Scaffold(body: Text('search page')),
        ),
        GoRoute(
          path: Routes.cartPreview,
          builder: (_, _) => const Scaffold(body: Text('cart page')),
        ),
        GoRoute(path: _CoverPage.path, builder: (_, _) => const _CoverPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cart),
          BlocProvider<AuthSessionCubit>.value(value: session),
          BlocProvider<LocalizationCubit>.value(value: localization),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reducedMotion),
            child: Directionality(textDirection: direction, child: child!),
          ),
        ),
      ),
    );
    unawaited(router.push(Routes.productListing, extra: args));
    await tester.pump();
    // Past the route transition, the hero's rise and the grid's reveal.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return router;
  }

  /// Unmounts the page so its timers (the countdown) stop before the end.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Finder heading() => find.textContaining(_heading, findRichText: true);

  ScrollPosition gridPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      )
      .position;

  group('collection look', () {
    testWidgets('store name in the bar, the hero, the grid, no toolbar', (
      tester,
    ) async {
      await pumpListing(tester, _bestSellers());

      expect(find.byType(CollectionFrame), findsOneWidget);
      expect(find.byType(CatalogAppBar), findsNothing);
      expect(find.text('Jm3eia'), findsOneWidget);
      expect(heading(), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.text('all 0'), findsOneWidget);
      expect(find.byType(ListingToolbar), findsNothing);
      expect(find.byType(ListingResultsCount), findsNothing);
      expect(find.byType(CountdownChip), findsNothing);
      expect(
        find.byType(RoundOutlinedButton),
        findsNWidgets(2),
        reason: 'back + search',
      );
      expect(products.requests.single.query.collectionSlug, 'best-sellers');
      await unmount(tester);
    });

    testWidgets('a brand opens as a collection page too', (tester) async {
      await pumpListing(
        tester,
        ProductListingArgs.brand(slug: 'almarai', title: 'Almarai'),
      );

      expect(find.byType(CollectionFrame), findsOneWidget);
      expect(find.textContaining('Almarai', findRichText: true), findsWidgets);
      expect(products.requests.single.query.brandSlug, 'almarai');
      await unmount(tester);
    });

    testWidgets('tabs come with two categories; a tap re-scopes the list', (
      tester,
    ) async {
      await pumpListing(tester, _bestSellers());

      expect(find.byType(CollectionTabStrip), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Snacks & Chocolate'), findsOneWidget);
      expect(find.text('Ice Cream'), findsOneWidget);
      expect(
        tester
            .widget<CollectionTabStrip>(find.byType(CollectionTabStrip))
            .selected,
        0,
      );

      await tester.tap(find.text('Ice Cream'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final scoped = products.requests.last.query;
      expect(scoped.categorySlug, 'ice-cream');
      expect(scoped.collectionSlug, 'best-sellers', reason: 'same list');
      expect(
        tester
            .widget<CollectionTabStrip>(find.byType(CollectionTabStrip))
            .selected,
        2,
      );
      expect(find.text('ice-cream 0'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(products.requests.last.query.categorySlug, isNull);
      await unmount(tester);
    });

    testWidgets('one category with products: no tabs', (tester) async {
      await register(tabsReply: const Right([_snacks]));
      await pumpListing(tester, _bestSellers());

      expect(find.byType(CollectionTabStrip), findsNothing);
      expect(heading(), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('tabs that fail stay hidden; the list still shows', (
      tester,
    ) async {
      await register(tabsReply: const Left(NetworkFailure()));
      await pumpListing(tester, _bestSellers());

      expect(tabs.calls, 1);
      expect(find.byType(CollectionTabStrip), findsNothing);
      expect(find.text('all 0'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a flash sale counts down in the hero until it ends', (
      tester,
    ) async {
      await pumpListing(
        tester,
        _bestSellers(endsAt: DateTime.now().add(const Duration(hours: 2))),
      );
      expect(find.byType(CountdownChip), findsOneWidget);
      await unmount(tester);

      await pumpListing(
        tester,
        _bestSellers(
          endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      expect(find.byType(CountdownChip), findsNothing);
      await unmount(tester);
    });

    testWidgets('search opens the search page', (tester) async {
      final router = await pumpListing(tester, _bestSellers());

      await tester.tap(find.byType(RoundOutlinedButton).last);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, Routes.search);
      expect(find.text('search page'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a tab tapped deep in the grid keeps the tabs pinned', (
      tester,
    ) async {
      await register(productCount: 30);
      await pumpListing(tester, _bestSellers());
      final heroExtent = tester.getSize(find.byType(CollectionHero)).height;

      gridPosition(tester).jumpTo(heroExtent * 6);
      await tester.pump();
      expect(heading(), findsNothing, reason: 'scrolled past the hero');

      await tester.tap(find.text('Snacks & Chocolate'));
      await tester.pump();
      expect(
        gridPosition(tester).pixels,
        moreOrLessEquals(heroExtent),
        reason: 'the tabs pin right under the bar, the list starts under them',
      );
      await tester.pump(const Duration(seconds: 1));
      expect(gridPosition(tester).pixels, moreOrLessEquals(heroExtent));
      expect(products.requests.last.query.categorySlug, 'snacks');
      await unmount(tester);
    });

    testWidgets('Arabic: the page reads right to left', (tester) async {
      useLanguage('ar');
      await pumpListing(tester, _bestSellers(), direction: TextDirection.rtl);

      expect(tester.takeException(), isNull);
      expect(find.text('جميعة'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(heading(), findsOneWidget);
      final buttons = find.byType(RoundOutlinedButton);
      final back = tester.getCenter(buttons.first);
      final search = tester.getCenter(buttons.last);
      expect(back.dx, greaterThan(search.dx), reason: 'back sits on the right');
      expect(
        Directionality.of(tester.element(find.byType(CollectionTabStrip))),
        TextDirection.rtl,
      );
      await unmount(tester);
    });

    testWidgets('under reduced motion everything is simply there', (
      tester,
    ) async {
      await pumpListing(tester, _bestSellers(), reducedMotion: true);

      expect(heading(), findsOneWidget);
      final heroFade = tester.widget<Opacity>(
        find.ancestor(of: heading(), matching: find.byType(Opacity)).first,
      );
      expect(heroFade.opacity, 1);
      expect(find.byType(CollectionTabStrip), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await unmount(tester);
    });
  });

  group('plain look', () {
    testWidgets('search results keep the catalogue app bar and toolbar', (
      tester,
    ) async {
      await pumpListing(
        tester,
        const ProductListingArgs(
          title: 'Results for milk',
          query: CatalogProductQuery(search: 'milk'),
        ),
      );

      expect(find.byType(CatalogAppBar), findsOneWidget);
      expect(find.text('Results for milk'), findsOneWidget);
      expect(find.byType(CollectionFrame), findsNothing);
      expect(find.byType(ListingToolbar), findsOneWidget);
      expect(find.byType(ListingResultsCount), findsOneWidget);
      expect(tabs.calls, 0, reason: 'no tabs are looked for');
      await unmount(tester);
    });
  });

  group('View cart pill', () {
    testWidgets('rises in with the first item and opens the cart', (
      tester,
    ) async {
      final router = await pumpListing(tester, _bestSellers());
      expect(find.byType(ViewCartPill), findsNothing);

      cartStates.add(_basket(qty: 2, subtotalFils: 2500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ViewCartPill), findsOneWidget);
      expect(
        tester.getSize(find.byType(CatalogCartBar)).height,
        lessThan(ViewCartPill.height),
        reason: 'still rising',
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('View cart'), findsOneWidget);
      expect(
        tester.getSize(find.byType(CatalogCartBar)).height,
        greaterThan(ViewCartPill.height),
      );

      await tester.tap(find.byType(ViewCartPill));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, Routes.cartPreview);
      await unmount(tester);
    });

    testWidgets('comes and goes at once under reduced motion', (tester) async {
      await pumpListing(tester, _bestSellers(), reducedMotion: true);

      cartStates.add(_basket(qty: 1, subtotalFils: 1000));
      await tester.pump();
      await tester.pump();
      expect(
        tester.getSize(find.byType(CatalogCartBar)).height,
        greaterThan(ViewCartPill.height),
      );

      cartStates.add(const CartState(isRestored: true));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ViewCartPill), findsNothing);
      await unmount(tester);
    });

    testWidgets('a page behind another never takes the flights', (
      tester,
    ) async {
      // Almost at the end of a flight; the decelerating curve is ~1 by then.
      const nearlyLanded = Duration(milliseconds: 380);
      const coverThumb = Key('cover-thumb');
      const listingThumb = Key('listing-thumb');
      final router = await pumpListing(tester, _bestSellers());

      unawaited(router.push(_CoverPage.path));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      // The page on top fills the basket: the covered listing's pill appears.
      cartStates.add(_basket(qty: 1, subtotalFils: 1000));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ViewCartPill), findsNothing);
      expect(find.byType(ViewCartPill, skipOffstage: false), findsOneWidget);

      FlyToCart.fly(
        tester.element(find.byKey(_CoverPage.source)),
        sourceKey: _CoverPage.source,
        thumbnail: const SizedBox(key: coverThumb),
      );
      await tester.pump();
      expect(
        find.byKey(coverThumb),
        findsOneWidget,
        reason: 'the flight still goes to the page on screen',
      );
      await tester.pump(nearlyLanded);
      final coverTarget = tester.getCenter(find.byKey(_CoverPage.target));
      final coverLanding = tester.getCenter(find.byKey(coverThumb));
      expect(coverLanding.dx, moreOrLessEquals(coverTarget.dx, epsilon: 2));
      expect(coverLanding.dy, moreOrLessEquals(coverTarget.dy, epsilon: 2));
      await tester.pump(AppMotion.slow);
      expect(find.byKey(coverThumb), findsNothing);

      // Uncovered, the listing's disc takes the flights again.
      router.pop();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(ViewCartPill), findsOneWidget);
      FlyToCart.flyFrom(
        tester.element(find.text('all 0')),
        thumbnail: const SizedBox(key: listingThumb),
      );
      await tester.pump();
      expect(find.byKey(listingThumb), findsOneWidget);
      await tester.pump(nearlyLanded);
      final disc = tester
          .widget<ViewCartPill>(find.byType(ViewCartPill))
          .targetKey!;
      final discCenter = tester.getCenter(find.byKey(disc));
      final listingLanding = tester.getCenter(find.byKey(listingThumb));
      expect(listingLanding.dx, moreOrLessEquals(discCenter.dx, epsilon: 2));
      expect(listingLanding.dy, moreOrLessEquals(discCenter.dy, epsilon: 2));
      await tester.pump(AppMotion.slow);
      await unmount(tester);
    });
  });
}
