// The Hero product page: the full-bleed gallery under a rounded
// white sheet, the tag chips, the brand link and the description folded
// behind an inline "More", size cards, the related products split into
// "Similar products" and "Shop more for less" rails of shelf cards wired to
// the cart, the white top bar that fades in with the product's name once the
// gallery scrolls away, the buy bar's deal badge over its price and its
// "Add to cart" pill that says "Added ✓" for a moment and becomes a stepper
// of the cart line, the rating link that brings the reviews up under the
// bar, Arabic (right to left), reduced motion and a small phone at a large
// text scale.
import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/routes/route_args/product_listing_args.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/config/theme/app_shadows.dart';
import 'package:hero_mart/src/config/theme/app_spacing.dart';
import 'package:hero_mart/src/core/domain/entities/brand_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_variant_entity.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/hero_card_image.dart';
import 'package:hero_mart/src/core/widgets/shelf_add_button.dart';
import 'package:hero_mart/src/core/widgets/shelf_marker_painter.dart';
import 'package:hero_mart/src/core/widgets/shelf_product_card.dart';
import 'package:hero_mart/src/core/widgets/shelf_save_badge.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_reviews.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_reviews_cubit.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_back_button.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_bar_price.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_body.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_bottom_bar.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_brand_link.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_cart_action.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_cart_cta.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_cta_stepper.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_description_text.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_gallery.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_info_block.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_product_rail.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_rating_summary.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_reviews_section.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_section_divider.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_size_card.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_step_button.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_stock_note.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_tag_chips.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_top_bar.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_variant_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdp_test_fakes.dart';

const String _description =
    'Fresh full-fat cow milk from local farms, pasteurised and chilled the '
    'same day it is collected. Rich in calcium and protein, it is lovely on '
    'its own, poured over cereal, or in your morning tea and coffee. Keep it '
    'refrigerated between 2 and 6 degrees and finish it within three days of '
    'opening. Shake well before use. Packed in a recyclable carton.';

const CatalogProductEntity _milk = CatalogProductEntity(
  id: 'milk',
  slug: 'fresh-milk',
  name: 'Fresh Milk 1L',
  priceFils: 500,
  compareAtFils: 625,
  stock: 3,
  tags: ['best-seller'],
  unitOfSale: UnitOfSale.litre,
);

const List<CatalogProductEntity> _related = [
  CatalogProductEntity(
    id: 'laban',
    slug: 'laban',
    name: 'Laban 1L',
    priceFils: 350,
    stock: 20,
  ),
  CatalogProductEntity(
    id: 'yoghurt',
    slug: 'yoghurt',
    name: 'Yoghurt 500g',
    priceFils: 450,
    stock: 20,
  ),
];

/// A related product on a deal: it goes to "Shop more for less".
const CatalogProductEntity _cheese = CatalogProductEntity(
  id: 'cheese',
  slug: 'cheese',
  name: 'Cheddar 200g',
  priceFils: 900,
  compareAtFils: 1000,
  stock: 20,
);

const BrandEntity _brand = BrandEntity(
  id: 'b1',
  slug: 'almarai',
  name: 'Almarai',
);

const ProductDetail _detail = ProductDetail(
  product: _milk,
  description: _description,
  brand: _brand,
  related: _related,
);

/// The same milk with a rating, so the "★ 4.5 · 10 reviews" link shows.
const ProductDetail _ratedDetail = ProductDetail(
  product: CatalogProductEntity(
    id: 'milk',
    slug: 'fresh-milk',
    name: 'Fresh Milk 1L',
    priceFils: 500,
    compareAtFils: 625,
    stock: 3,
    tags: ['best-seller'],
    unitOfSale: UnitOfSale.litre,
    ratingAverage: 4.5,
    ratingCount: 10,
  ),
  description: _description,
  brand: _brand,
  related: _related,
);

/// Related products on a deal and not: two rails.
const ProductDetail _splitDetail = ProductDetail(
  product: _milk,
  description: _description,
  brand: _brand,
  related: [..._related, _cheese],
);

/// Only deals among the related products: one rail, "Shop more for less".
const ProductDetail _dealsOnlyDetail = ProductDetail(
  product: _milk,
  related: [_cheese],
);

/// Plenty in stock, no deal, no Pro price: nothing to note.
const CatalogProductEntity _plenty = CatalogProductEntity(
  id: 'water',
  slug: 'water',
  name: 'Water 1.5L',
  priceFils: 150,
  stock: 40,
);

/// A description that fits in the fold.
const ProductDetail _shortDetail = ProductDetail(
  product: _milk,
  description: 'Fresh milk.',
);

const ProductDetail _soldOutDetail = ProductDetail(
  product: CatalogProductEntity(
    id: 'milk',
    slug: 'fresh-milk',
    name: 'Fresh Milk 1L',
    priceFils: 500,
  ),
);

const CatalogProductEntity _cola = CatalogProductEntity(
  id: 'cola',
  slug: 'cola',
  name: 'Cola',
  type: CatalogProductType.variant,
);

/// A variant product: a plain size, a size on a deal, a sold-out size.
const ProductDetail _sizesDetail = ProductDetail(
  product: _cola,
  variants: [
    CatalogVariantEntity(id: 'can', name: '250ml', priceFils: 600, stock: 9),
    CatalogVariantEntity(
      id: 'pack',
      name: '4x250ml',
      priceFils: 2050,
      compareAtFils: 2200,
      stock: 9,
    ),
    CatalogVariantEntity(id: 'crate', name: '24x250ml', priceFils: 11000),
  ],
  related: [..._related, _cheese],
);

/// Every size sold out: nothing is chosen.
const ProductDetail _noSizeDetail = ProductDetail(
  product: _cola,
  variants: [CatalogVariantEntity(id: 'can', name: '250ml', priceFils: 600)],
);

/// Ten written reviews: a reviews block taller than the screen.
final ProductReviews _tenReviews = ProductReviews(
  reviews: [
    for (var i = 0; i < 10; i++)
      ProductReview(
        id: 'r$i',
        rating: 5 - i % 3,
        createdAt: DateTime(2026, 9, 1 + i),
        title: 'Review $i',
        body: 'Fresh, cold and on time. Would buy again. ' * 2,
        customerName: 'Customer $i',
      ),
  ],
  page: 1,
  hasMore: false,
  total: 10,
  ratingAverage: 4.5,
  ratingCount: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> en;
  late Map<String, dynamic> ar;

  void speak(String code) => Localization.load(
    Locale(code),
    translations: Translations(code == 'ar' ? ar : en),
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    en = withNewProductKeys(
      json.decode(await rootBundle.loadString('assets/i18n/en.json'))
          as Map<String, dynamic>,
      'en',
    );
    ar = withNewProductKeys(
      json.decode(await rootBundle.loadString('assets/i18n/ar.json'))
          as Map<String, dynamic>,
      'ar',
    );
    speak('en');
    // What the Material localizations load in the app: the date symbols.
    await initializeDateFormatting('en');
  });

  late ProductDetailCubit detail;
  late ProductReviewsCubit reviews;
  late FakeCartCubit cart;
  late AuthSessionCubit session;
  late List<Object?> listings;

  setUp(() {
    detail = ProductDetailCubit(
      const StubWatchDetail(_detail),
      const StubGetOffer(),
      slug: _milk.slug,
    );
    reviews = ProductReviewsCubit(
      const StubWatchReviews(),
      const StubGetReviews(),
      slug: _milk.slug,
    );
    cart = FakeCartCubit();
    session = signedOutSession();
    listings = [];
  });

  tearDown(() async {
    await detail.close();
    await reviews.close();
    await cart.close();
    await session.close();
  });

  /// Serves [served] (and [served reviews]) instead of the milk.
  Future<void> serve(
    ProductDetail served, {
    ProductReviews servedReviews = ProductReviews.empty,
  }) async {
    await detail.close();
    await reviews.close();
    detail = ProductDetailCubit(
      StubWatchDetail(served),
      const StubGetOffer(),
      slug: _milk.slug,
    );
    reviews = ProductReviewsCubit(
      StubWatchReviews(servedReviews),
      StubGetReviews(servedReviews),
      slug: _milk.slug,
    );
  }

  /// Starts from a basket that already holds [quantity] of [product].
  Future<void> holding(CatalogProductEntity product, int quantity) async {
    await cart.close();
    cart = FakeCartCubit.holding(product, quantity);
  }

  /// The product page on a phone ([width] dp wide), loaded, under a router
  /// that records the brand listings it opens. [withLocale] puts the app's
  /// EasyLocalization (English) above it, which review tiles need for their
  /// dates.
  Future<void> pumpPage(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    bool reducedMotion = false,
    bool withLocale = false,
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width * 3, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final galleryKey = GlobalKey();
    unawaited(detail.load());
    unawaited(reviews.load());
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Directionality(
              textDirection: direction,
              child: Scaffold(
                backgroundColor: AppColors.white,
                body: PdpBody(galleryKey: galleryKey),
                bottomNavigationBar: PdpBottomBar(galleryKey: galleryKey),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.productListing,
          builder: (_, state) {
            listings.add(state.extra);
            return const Scaffold();
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    final page = MultiBlocProvider(
      providers: [
        BlocProvider<ProductDetailCubit>.value(value: detail),
        BlocProvider<ProductReviewsCubit>.value(value: reviews),
        BlocProvider<CartCubit>.value(value: cart),
        BlocProvider<AuthSessionCubit>.value(value: session),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
    await tester.pumpWidget(
      withLocale
          ? EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('ar')],
              path: 'assets/i18n',
              fallbackLocale: const Locale('en'),
              startLocale: const Locale('en'),
              saveLocale: false,
              child: page,
            )
          : page,
    );
    await tester.pump();
  }

  /// Lets every entrance, flight and switch run out.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// How visible [finder] is through its fades.
  double opacityOf(WidgetTester tester, Finder finder) {
    var opacity = 1.0;
    final fades = find.ancestor(
      of: finder,
      matching: find.byWidgetPredicate(
        (widget) => widget is FadeTransition || widget is Opacity,
      ),
    );
    for (final widget in tester.widgetList(fades)) {
      opacity *= widget is FadeTransition
          ? widget.opacity.value
          : (widget as Opacity).opacity;
    }
    return opacity;
  }

  /// The lime marker under the buy bar's deal price.
  ShelfMarkerPainter marker(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(PdpBarPrice),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<ShelfMarkerPainter>()
      .single;

  /// Scrolls the page until [finder] sits mid-screen, clear of the bars.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    unawaited(Scrollable.ensureVisible(tester.element(finder), alignment: 0.5));
    await settle(tester);
  }

  /// The rolling price reads [text] to a screen reader.
  Finder rollingPrice(String text) =>
      find.bySemanticsLabel(RegExp(RegExp.escape(text)));

  final similarTitle = find.text('Similar products');
  final dealsTitle = find.text('Shop more for less');
  final cta = find.byType(PdpCartCta);
  final stepper = find.byType(PdpCtaStepper);

  int stepperQuantity(WidgetTester tester) =>
      tester.widget<PdpCtaStepper>(stepper).quantity;

  group('buy bar', () {
    testWidgets('Add → "Added ✓" → a stepper of the cart line, back to Add '
        'at nothing', (tester) async {
      await pumpPage(tester);
      await settle(tester);
      expect(find.text('Add to cart'), findsOneWidget);
      expect(stepper, findsNothing);

      expect(find.byType(HeroCardImage), findsNothing);
      await tester.tap(cta);
      await tester.pump();
      expect(cart.adds, [('milk', null, 1)]);
      // The product takes off from the gallery towards the cart.
      final thumb = find.byType(HeroCardImage);
      expect(thumb, findsOneWidget);
      expect(
        tester
            .getRect(find.byType(PdpGallery))
            .contains(tester.getCenter(thumb)),
        isTrue,
      );

      // The switch plays (its clock starts on the frame after the tap).
      const step = Duration(milliseconds: 100);
      for (var i = 0; i < 4; i++) {
        await tester.pump(step);
      }
      expect(AppMotion.medium, lessThan(step * 3));
      expect(find.text('Added'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Add to cart'), findsNothing);

      // Still there just before the moment is over…
      await tester.pump(PdpCartCta.addedHold - step * 4 - step ~/ 2);
      expect(find.text('Added'), findsOneWidget);

      // …then the stepper of the cart line takes over.
      await settle(tester);
      expect(find.text('Added'), findsNothing);
      expect(stepper, findsOneWidget);
      expect(stepperQuantity(tester), 1);

      // + adds one to that line.
      await tester.tap(find.byType(PdpStepButton).last);
      await settle(tester);
      expect(cart.increments, 1);
      expect(stepperQuantity(tester), 2);

      // − down to nothing: the pill is "Add to cart" again.
      await tester.tap(find.byType(PdpStepButton).first);
      await settle(tester);
      expect(stepperQuantity(tester), 1);
      await tester.tap(find.byType(PdpStepButton).first);
      await settle(tester);
      expect(cart.decrements, 2);
      expect(stepper, findsNothing);
      expect(find.text('Add to cart'), findsOneWidget);
    });

    testWidgets('every change of the pill morphs in place, none is a cut', (
      tester,
    ) async {
      await pumpPage(tester);
      await settle(tester);
      // One frame for the switch's clock to start, then partway through it.
      const midway = Duration(milliseconds: 50);
      expect(midway, lessThan(AppMotion.medium));
      // The pill's own switcher (the stepper's rolling count has another).
      final switcher = find
          .descendant(of: cta, matching: find.byType(AnimatedSwitcher))
          .first;
      final pill = tester.state(switcher);

      // Add → Added: the same pill, the two labels cross-fading.
      await tester.tap(cta);
      await tester.pump();
      await tester.pump(midway);
      expect(tester.state(switcher), same(pill));
      expect(find.text('Add to cart'), findsOneWidget);
      expect(find.text('Added'), findsOneWidget);
      expect(opacityOf(tester, find.text('Add to cart')), lessThan(1));
      expect(opacityOf(tester, find.text('Added')), lessThan(1));

      // Added → stepper, still the same pill.
      await tester.pump(PdpCartCta.addedHold);
      await settle(tester);
      expect(stepper, findsOneWidget);
      expect(tester.state(switcher), same(pill));

      // Stepper → Add as the line runs out: the stepper fades out while
      // "Add to cart" comes back.
      await tester.tap(find.byType(PdpStepButton).first);
      await tester.pump();
      await tester.pump(midway);
      expect(cart.decrements, 1);
      expect(tester.state(switcher), same(pill));
      expect(stepper, findsOneWidget);
      expect(find.text('Add to cart'), findsOneWidget);
      expect(opacityOf(tester, stepper), lessThan(1));
      await settle(tester);
      expect(stepper, findsNothing);
      expect(find.text('Add to cart'), findsOneWidget);
      expect(tester.state(switcher), same(pill));
    });

    testWidgets('the price rolls to the line total of the basket', (
      tester,
    ) async {
      await holding(_milk, 1);
      await pumpPage(tester);
      await settle(tester);
      final semantics = tester.ensureSemantics();

      expect(rollingPrice('KD 0.500'), findsOneWidget);
      // The struck price of the deal follows the line.
      expect(find.text('KD 0.625'), findsOneWidget);
      await tester.tap(find.byType(PdpStepButton).last);
      await settle(tester);
      expect(rollingPrice('KD 1.000'), findsOneWidget);
      expect(find.text('KD 1.250'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a step that cannot move is inert', (tester) async {
      // All three in stock are in the basket already.
      await holding(_milk, 3);
      await pumpPage(tester);
      await settle(tester);

      final plus = find.byType(PdpStepButton).last;
      expect(tester.widget<PdpStepButton>(plus).active, isFalse);
      await tester.tap(plus);
      await settle(tester);
      expect(cart.increments, 0);
      expect(stepperQuantity(tester), 3);
    });

    testWidgets('out of stock: a grey pill that does not react', (
      tester,
    ) async {
      await serve(_soldOutDetail);
      await pumpPage(tester);
      await settle(tester);

      expect(
        find.descendant(of: cta, matching: find.text('Out of stock')),
        findsOneWidget,
      );
      await tester.tap(cta);
      await settle(tester);
      expect(cart.adds, isEmpty);
      expect(find.text('Added'), findsNothing);
      expect(stepper, findsNothing);
    });

    testWidgets('no size to choose: "Choose options", and no price', (
      tester,
    ) async {
      await serve(_noSizeDetail);
      await pumpPage(tester);
      await settle(tester);

      expect(
        find.descendant(of: cta, matching: find.text('Choose options')),
        findsOneWidget,
      );
      expect(find.byType(PdpBarPrice), findsNothing);
      await tester.tap(cta);
      await settle(tester);
      expect(cart.adds, isEmpty);
    });
  });

  group('top bar', () {
    testWidgets('the white bar fades in with the name once the gallery is '
        'gone', (tester) async {
      await pumpPage(tester);
      await settle(tester);

      final title = find.descendant(
        of: find.byType(PdpTopBar),
        matching: find.text(_milk.name),
      );
      double titleOpacity() => tester
          .widget<Opacity>(
            find.ancestor(of: title, matching: find.byType(Opacity)).first,
          )
          .opacity;
      BoxDecoration bar() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(PdpTopBar),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;

      // Over the gallery: only the round back and cart buttons.
      expect(titleOpacity(), 0);
      expect(bar().color!.a, 0);
      expect(bar().boxShadow, isNull);
      expect(
        find.descendant(
          of: find.byType(PdpTopBar),
          matching: find.byIcon(Icons.search_rounded),
        ),
        findsNothing,
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
      await settle(tester);
      expect(titleOpacity(), 1);
      expect(bar().color, AppColors.white);
      expect(bar().boxShadow, AppShadows.barBottom);

      // Back to the top: see-through again.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 2800));
      await settle(tester);
      expect(titleOpacity(), 0);
      expect(bar().boxShadow, isNull);
    });
  });

  group('rating link', () {
    // A notched phone: the bar paints under a 47 dp status bar.
    const statusBar = 47.0;

    /// The rated page, loaded and settled, with its status bar.
    Future<void> pumpRated(
      WidgetTester tester, {
      bool reducedMotion = false,
    }) async {
      await serve(_ratedDetail, servedReviews: _tenReviews);
      tester.view.padding = const FakeViewPadding(top: statusBar * 3);
      await pumpPage(tester, reducedMotion: reducedMotion, withLocale: true);
      await settle(tester);
    }

    final reviewsBlock = find.byType(PdpReviewsSection);

    /// The reviews sit right under the solid bar, their heading in full view.
    void expectReviewsUnderBar(WidgetTester tester) {
      final bar = tester.getRect(find.byType(PdpTopBar));
      expect(bar.bottom, statusBar + PdpTopBar.barHeight);
      expect(tester.getRect(reviewsBlock).top, moreOrLessEquals(bar.bottom));
      final heading = find.descendant(
        of: reviewsBlock,
        matching: find.text('Reviews'),
      );
      expect(tester.getRect(heading).top, greaterThanOrEqualTo(bar.bottom));
    }

    testWidgets('glides the reviews up to just under the solid top bar', (
      tester,
    ) async {
      await pumpRated(tester);
      final before = tester.getRect(reviewsBlock).top;

      await tester.tap(find.byType(PdpRatingSummary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final gliding = tester.getRect(reviewsBlock).top;
      expect(gliding, lessThan(before));

      await settle(tester);
      expect(gliding, greaterThan(tester.getRect(reviewsBlock).top));
      expectReviewsUnderBar(tester);
    });

    testWidgets('reduced motion: jumps straight there', (tester) async {
      await pumpRated(tester, reducedMotion: true);

      await tester.tap(find.byType(PdpRatingSummary));
      await tester.pump();
      expectReviewsUnderBar(tester);
    });
  });

  group('blocks', () {
    testWidgets('the tags, brand, name and stock of the info block; the deal '
        'over the buy bar\'s price', (tester) async {
      await holding(_milk, 2);
      await pumpPage(tester);
      await settle(tester);
      final semantics = tester.ensureSemantics();

      final info = find.byType(PdpInfoBlock);
      // The tag as a flat grey chip at the top of the sheet.
      final chip = find.descendant(
        of: find.byType(PdpTagChips),
        matching: find.text('Best seller'),
      );
      expect(find.descendant(of: info, matching: chip), findsOneWidget);
      expect(tester.widget<Text>(chip).style!.color, AppColors.secondaryText);
      final brand = find.descendant(of: info, matching: find.text('Almarai'));
      expect(brand, findsOneWidget);
      expect(
        tester.widget<Text>(brand).style!.decoration,
        TextDecoration.underline,
      );
      expect(tester.getRect(chip).bottom, lessThan(tester.getRect(brand).top));
      expect(
        find.descendant(of: info, matching: find.text(_milk.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: info, matching: find.text('Only 3 left')),
        findsOneWidget,
      );
      // The deal badge sits over the price it explains, not in the sheet.
      final save = find.descendant(
        of: find.byType(PdpBottomBar),
        matching: find.text('Save 20%'),
      );
      expect(save, findsOneWidget);
      expect(
        find.descendant(of: info, matching: find.byType(ShelfSaveBadge)),
        findsNothing,
      );
      expect(
        tester.getRect(save).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(PdpBarPrice)).top),
      );
      // The basket shows in the buy bar now: the stepper and the line total.
      expect(find.text('2 in cart'), findsNothing);
      expect(stepperQuantity(tester), 2);
      expect(rollingPrice('KD 1.000'), findsOneWidget);
      // The marker under the deal price has drawn itself in.
      expect(marker(tester).progress.value, 1);
      semantics.dispose();
    });

    testWidgets('the brand link opens the brand listing', (tester) async {
      await pumpPage(tester);
      await settle(tester);

      await tester.tap(find.byType(PdpBrandLink));
      await settle(tester);
      expect(listings, hasLength(1));
      final args = listings.single! as ProductListingArgs;
      expect(args.query.brandSlug, _brand.slug);
      expect(args.title, _brand.name);
    });

    testWidgets('the description folds behind an inline "More"', (
      tester,
    ) async {
      await pumpPage(tester);
      await settle(tester);

      final text = find.descendant(
        of: find.byType(PdpDescriptionText),
        matching: find.byType(RichText),
      );
      String shown() => tester.widget<RichText>(text).text.toPlainText();
      expect(shown(), endsWith('… More'));
      expect(shown(), isNot(contains('recyclable carton')));
      expect(
        tester.widget<RichText>(text).maxLines,
        PdpDescriptionText.foldedLines,
      );
      // "More" really ends the last line, not a clipped third one (the
      // theme's letter spacing is part of the measure).
      expect(
        tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
        isFalse,
      );
      final folded = tester.getSize(text).height;

      await tester.tapOnText(find.textRange.ofSubstring('More'));
      await settle(tester);
      expect(shown(), startsWith(_description));
      expect(shown(), endsWith('Less'));
      expect(tester.getSize(text).height, greaterThan(folded));

      // The whole description is taller now: bring its end into view.
      await reveal(tester, find.byType(PdpDescriptionText));
      await tester.tapOnText(find.textRange.ofSubstring('Less'));
      await settle(tester);
      expect(shown(), endsWith('… More'));
      expect(tester.getSize(text).height, folded);
    });

    testWidgets('plenty in stock, no deal, no tag: nothing to note', (
      tester,
    ) async {
      await serve(const ProductDetail(product: _plenty));
      await pumpPage(tester);
      await settle(tester);

      expect(find.text('In stock'), findsNothing);
      expect(find.text('Out of stock'), findsNothing);
      expect(find.byType(PdpStockNote), findsNothing);
      expect(find.byType(PdpTagChips), findsNothing);
      expect(find.byType(ShelfSaveBadge), findsNothing);
    });

    testWidgets('a description that fits has no link', (tester) async {
      await serve(_shortDetail);
      await pumpPage(tester);
      await settle(tester);

      expect(find.text('Fresh milk.'), findsOneWidget);
      expect(find.textContaining('More'), findsNothing);
    });

    testWidgets('size cards select, and dim the ones that cannot be bought', (
      tester,
    ) async {
      await serve(_sizesDetail);
      await pumpPage(tester);
      await settle(tester);

      expect(find.text('Size'), findsOneWidget);
      final cards = find.byType(PdpSizeCard);
      expect(cards, findsNWidgets(3));
      final can = find.byKey(const ValueKey('can'));
      final pack = find.byKey(const ValueKey('pack'));
      final crate = find.byKey(const ValueKey('crate'));
      // Two to a row on a phone.
      expect(tester.getRect(can).top, tester.getRect(pack).top);
      expect(tester.getRect(can).height, tester.getRect(pack).height);
      expect(tester.getRect(crate).top, greaterThan(tester.getRect(can).top));

      Border borderOf(Finder card) =>
          (tester
                          .widget<AnimatedContainer>(
                            find.descendant(
                              of: card,
                              matching: find.byType(AnimatedContainer),
                            ),
                          )
                          .decoration!
                      as BoxDecoration)
                  .border!
              as Border;

      // The first size that can be bought is chosen: a 2 dp ink border.
      expect(detail.state.selectedVariantId, 'can');
      expect(borderOf(can).top.width, 2);
      expect(borderOf(can).top.color, AppColors.primaryText);
      expect(borderOf(pack).top.width, 1);
      // The deal: its price marked in lime, the struck price below.
      expect(
        tester
            .widgetList<CustomPaint>(
              find.descendant(of: pack, matching: find.byType(CustomPaint)),
            )
            .map((paint) => paint.painter)
            .whereType<ShelfMarkerPainter>(),
        hasLength(1),
      );
      expect(
        find.descendant(of: pack, matching: find.text('KD 2.200')),
        findsOneWidget,
      );
      // The sold-out size says so.
      expect(
        find.descendant(of: crate, matching: find.text('Out of stock')),
        findsOneWidget,
      );

      await reveal(tester, pack);
      await tester.tap(pack);
      await settle(tester);
      expect(detail.state.selectedVariantId, 'pack');
      expect(tester.widget<PdpSizeCard>(pack).selected, isTrue);
      expect(tester.widget<PdpSizeCard>(can).selected, isFalse);

      await tester.tap(crate);
      await settle(tester);
      expect(detail.state.selectedVariantId, 'pack');

      final semantics = tester.ensureSemantics();
      // One button per card: chosen or not, and whether it can be.
      expect(
        tester.getSemantics(crate),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: false,
        ),
      );
      expect(tester.getSemantics(crate).label, contains('Out of stock'));
      expect(
        tester.getSemantics(pack),
        isSemantics(
          isButton: true,
          isEnabled: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('related products split into two rails by discount', (
      tester,
    ) async {
      await serve(_splitDetail);
      await pumpPage(tester);
      await settle(tester);

      expect(find.byType(PdpProductRail), findsNWidgets(2));
      expect(similarTitle, findsOneWidget);
      expect(dealsTitle, findsOneWidget);
      final similar = find.byType(PdpProductRail).first;
      final deals = find.byType(PdpProductRail).last;
      expect(
        find.descendant(of: similar, matching: find.byType(ShelfProductCard)),
        findsNWidgets(2),
      );
      final dealCards = find.descendant(
        of: deals,
        matching: find.byType(ShelfProductCard),
      );
      expect(dealCards, findsOneWidget);
      expect(tester.widget<ShelfProductCard>(dealCards).product.id, 'cheese');
      expect(
        tester.getRect(deals).top,
        greaterThan(tester.getRect(similar).top),
      );
      // A hairline before the first rail, none between the two rails, one
      // before the reviews.
      final lines = find.byType(PdpSectionDivider);
      expect(lines, findsNWidgets(2));
      expect(tester.getRect(lines.first).bottom, tester.getRect(similar).top);
      expect(tester.getRect(deals).top, tester.getRect(similar).bottom);
    });

    testWidgets('one rail when a group is empty', (tester) async {
      await pumpPage(tester);
      await settle(tester);
      expect(similarTitle, findsOneWidget);
      expect(dealsTitle, findsNothing);
    });

    testWidgets('only deals: only "Shop more for less"', (tester) async {
      await serve(_dealsOnlyDetail);
      await pumpPage(tester);
      await settle(tester);
      expect(similarTitle, findsNothing);
      expect(dealsTitle, findsOneWidget);
      // First rail on the page: the hairline goes above it.
      final lines = find.byType(PdpSectionDivider);
      expect(lines, findsNWidgets(2));
      expect(
        tester.getRect(lines.first).bottom,
        tester.getRect(find.byType(PdpProductRail)).top,
      );
    });

    testWidgets('hairlines only where Hero draws them', (tester) async {
      await serve(_sizesDetail);
      await pumpPage(tester);
      await settle(tester);

      // The options run straight on from the description…
      expect(
        tester.getRect(find.byType(PdpVariantSelector)).top,
        tester.getRect(find.byType(PdpInfoBlock)).bottom + AppSpacing.s16,
      );
      // …then one hairline before the first rail, none between the rails,
      // and one before the reviews.
      final similar = tester.getRect(find.byType(PdpProductRail).first);
      final deals = tester.getRect(find.byType(PdpProductRail).last);
      final lines = find.byType(PdpSectionDivider);
      expect(lines, findsNWidgets(2));
      expect(tester.getRect(lines.first).bottom, similar.top);
      expect(deals.top, similar.bottom);
      expect(
        tester.getRect(lines.last).bottom,
        tester.getRect(find.byType(PdpReviewsSection)).top,
      );
    });

    testWidgets('rail cards are shelf cards sized from the viewport, wired to '
        'the cart', (tester) async {
      await pumpPage(tester);
      await settle(tester);

      final cards = find.byType(ShelfProductCard);
      expect(cards, findsNWidgets(2));
      final width = PdpProductRail.cardWidthFor(390);
      expect(tester.getSize(cards.first).width, width);
      expect(
        tester.widget<ShelfProductCard>(cards.first).reservesTagLine,
        isFalse,
      );
      final rail = find.ancestor(
        of: cards.first,
        matching: find.byType(ListView),
      );
      // The rail is as tall as its tallest card, not room for every line.
      final railProducts = tester
          .widgetList<ShelfProductCard>(
            find.descendant(of: rail, matching: find.byType(ShelfProductCard)),
          )
          .map((card) => card.product);
      expect(
        tester.getSize(rail).height,
        ShelfProductCard.railHeight(
          tester.element(cards.first),
          width: width,
          products: railProducts,
          pro: false,
        ),
      );

      await reveal(tester, cards.first);
      await tester.tap(
        find.descendant(of: cards.first, matching: find.byType(ShelfAddButton)),
      );
      await tester.pump();
      expect(cart.adds, [('laban', null, 1)]);
      await settle(tester);
    });

    test('rail cards: about two and a half in view, within bounds', () {
      expect(PdpProductRail.cardWidthFor(390), closeTo(134.6, 0.1));
      expect(PdpProductRail.cardWidthFor(320), 112);
      expect(PdpProductRail.cardWidthFor(1024), 160);
    });

    testWidgets('the blocks under the name cascade in once', (tester) async {
      await pumpPage(tester);

      // Right after the load: the name stays put, the blocks are arriving.
      expect(
        opacityOf(
          tester,
          find.descendant(
            of: find.byType(PdpInfoBlock),
            matching: find.text(_milk.name),
          ),
        ),
        1,
      );
      expect(opacityOf(tester, similarTitle), lessThan(1));

      await settle(tester);
      expect(opacityOf(tester, similarTitle), 1);

      // Scrolled away and back: no second entrance.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1400));
      await tester.pump();
      expect(opacityOf(tester, similarTitle), 1);
      await settle(tester);
    });
  });

  testWidgets('reads right to left in Arabic', (tester) async {
    speak('ar');
    addTearDown(() => speak('en'));
    await pumpPage(tester, direction: TextDirection.rtl);
    await settle(tester);

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    // Back at the reading start (the right), the cart at the end.
    expect(
      tester.getCenter(find.byType(PdpBackButton)).dx,
      greaterThan(width / 2),
    );
    expect(
      tester.getCenter(find.byType(PdpCartAction)).dx,
      lessThan(width / 2),
    );
    // The brand and the name start at the right.
    expect(
      tester.getTopRight(find.byType(PdpBrandLink)).dx,
      moreOrLessEquals(width - 16),
    );
    expect(find.text('منتجات مشابهة'), findsOneWidget);
    expect(find.text('أضف إلى السلة'), findsOneWidget);
    expect(find.text('الأكثر مبيعاً'), findsOneWidget);
    expect(find.text('بقي 3 فقط'), findsOneWidget);
    expect(
      tester
          .widget<RichText>(
            find.descendant(
              of: find.byType(PdpDescriptionText),
              matching: find.byType(RichText),
            ),
          )
          .text
          .toPlainText(),
      endsWith('المزيد'),
    );
    // The deal marker draws from the right.
    expect(marker(tester).textDirection, TextDirection.rtl);
  });

  testWidgets('reduced motion: no cascade, no drawing, an instant switch', (
    tester,
  ) async {
    await pumpPage(tester, reducedMotion: true);

    // Not a millisecond has passed: everything is already in place.
    expect(opacityOf(tester, similarTitle), 1);
    expect(marker(tester).progress.value, 1);

    await tester.tap(cta);
    await tester.pump();
    await tester.pump();
    expect(cart.adds, [('milk', null, 1)]);
    expect(find.byType(HeroCardImage), findsNothing, reason: 'no flight');
    // Only the new label: the old one does not linger for a fade.
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Add to cart'), findsNothing);

    await tester.pump(PdpCartCta.addedHold);
    await tester.pump();
    await tester.pump();
    expect(find.text('Added'), findsNothing);
    expect(stepper, findsOneWidget);
    expect(stepperQuantity(tester), 1);

    // The line runs out: straight back to "Add to cart", no stepper left.
    await tester.tap(find.byType(PdpStepButton).first);
    await tester.pump();
    expect(stepper, findsNothing);
    expect(find.text('Add to cart'), findsOneWidget);
  });

  group('a 320 dp phone at text scale 1.3', () {
    Future<void> walkThePage(WidgetTester tester) async {
      await settle(tester);
      expect(tester.takeException(), isNull);
      // In the basket: the stepper and the line total.
      await tester.tap(cta);
      await settle(tester);
      expect(stepper, findsOneWidget);
      expect(tester.takeException(), isNull);
      // Every block, down to the end of the page.
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await settle(tester);
        expect(tester.takeException(), isNull);
      }
    }

    testWidgets('nothing overflows', (tester) async {
      await serve(_sizesDetail);
      await pumpPage(tester, width: 320, textScale: 1.3);
      await walkThePage(tester);
    });

    testWidgets('nothing overflows in Arabic', (tester) async {
      speak('ar');
      addTearDown(() => speak('en'));
      await serve(_splitDetail);
      await pumpPage(
        tester,
        width: 320,
        textScale: 1.3,
        direction: TextDirection.rtl,
      );
      await walkThePage(tester);
    });
  });
}
