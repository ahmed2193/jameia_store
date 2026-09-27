// The product page's depth and flight: the photos drift up behind the
// sheet at a slower pace (a pull past the top shows the gallery's grey),
// the name rises into the top bar as it fades in, a tapped photo flies into
// the full-screen viewer and back, and the tags sit as flat grey chips.
// Reduced motion: no drift, no rise, no flight.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/feature_routes/product_details_routes.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_merch_tag.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:hero_mart/src/features/product_details/presentation/pages/pdp_image_viewer_page.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_gallery_depth.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_photo.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_photo_flight.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_scaffold_view.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_section.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_sheet.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_tag_chips.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdp_test_fakes.dart';

const List<String> _photos = ['a.jpg', 'b.jpg'];

/// Another product's page, showing the same photos.
const String _otherProduct = '/other-product';

const ProductDetail _detail = ProductDetail(
  product: CatalogProductEntity(
    id: 'milk',
    slug: 'milk',
    name: 'Milk 1L',
    priceFils: 499,
    stock: 10,
  ),
  galleryUrls: _photos,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await speakEnglish();
  });

  /// The page frame of product [slug] with [_photos] over a sheet taller
  /// than the screen.
  Widget productPage(String slug) => Scaffold(
    body: PdpScaffoldView(
      productSlug: slug,
      title: 'Milk 1L',
      images: _photos,
      sections: [
        for (var i = 0; i < 8; i++)
          const PdpSection(child: SizedBox(height: 200)),
      ],
    ),
  );

  /// The frame of "milk" under the app's own product routes (the viewer
  /// among them), plus another product's page that slides up like one.
  Future<void> pumpFrame(
    WidgetTester tester, {
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final detail = ProductDetailCubit(
      const StubWatchDetail(_detail),
      const StubGetOffer(),
      slug: 'milk',
    );
    final cart = FakeCartCubit();
    addTearDown(() async {
      await detail.close();
      await cart.close();
    });
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => productPage('milk')),
        GoRoute(
          path: _otherProduct,
          pageBuilder: (_, state) => HeroSlideUpTransitionPage<Object?>(
            key: state.pageKey,
            child: productPage('milk-2l'),
          ),
        ),
        ...productDetailsRoutes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductDetailCubit>.value(value: detail),
          BlocProvider<CartCubit>.value(value: cart),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reducedMotion),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final list = find.byType(CustomScrollView);

  /// The page list's own position (not the gallery pager's).
  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)).first,
      )
      .position;

  /// How far the photos have drifted down against the page (found even
  /// once scrolled out of view).
  double drift(WidgetTester tester) => tester
      .widget<Transform>(
        find
            .descendant(
              of: find.byType(PdpGalleryDepth, skipOffstage: false),
              matching: find.byType(Transform, skipOffstage: false),
              skipOffstage: false,
            )
            .first,
      )
      .transform
      .getTranslation()
      .y;

  group('gallery depth', () {
    testWidgets('the photos drift up at 60 % of the page over a fixed grey '
        'backdrop', (tester) async {
      await pumpFrame(tester);
      expect(drift(tester), 0);

      position(tester).jumpTo(200);
      await tester.pump();
      expect(drift(tester), moreOrLessEquals(200 * PdpGalleryDepth.lag));

      // A finger drag follows the same way (still over the photos).
      await tester.drag(list, const Offset(0, -100));
      await tester.pump();
      final pixels = position(tester).pixels;
      expect(
        pixels,
        lessThan(
          PdpScaffoldView.galleryHeight(tester.element(list)) -
              PdpSheet.overlap,
        ),
      );
      expect(drift(tester), moreOrLessEquals(pixels * PdpGalleryDepth.lag));

      // Behind the list, the gallery's grey from the very top: what a pull
      // past the top uncovers is never the page's white.
      final stack = tester.widget<Stack>(
        find
            .descendant(
              of: find.byType(PdpScaffoldView),
              matching: find.byType(Stack),
            )
            .first,
      );
      final backdrop = stack.children.first as PositionedDirectional;
      expect(backdrop.top, 0);
      expect((backdrop.child as ColoredBox).color, AppColors.smallBackground);
      expect(
        backdrop.height,
        PdpScaffoldView.galleryHeight(tester.element(list)),
      );
    });

    testWidgets('once the sheet covers the photos, the drift holds still', (
      tester,
    ) async {
      await pumpFrame(tester);
      final pager =
          PdpScaffoldView.galleryHeight(tester.element(list)) -
          PdpSheet.overlap;

      position(tester).jumpTo(pager + 300);
      await tester.pump();
      expect(drift(tester), moreOrLessEquals(pager * PdpGalleryDepth.lag));
    });

    testWidgets('reduced motion: the photos scroll with the page', (
      tester,
    ) async {
      await pumpFrame(tester, reducedMotion: true);

      position(tester).jumpTo(300);
      await tester.pump();
      expect(drift(tester), 0);
    });
  });

  group('top bar', () {
    Finder title() => find.descendant(
      of: find.byType(PdpTopBar),
      matching: find.text('Milk 1L'),
    );

    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.ancestor(of: title(), matching: find.byType(Opacity)).first,
        )
        .opacity;

    double rise(WidgetTester tester) => tester
        .widget<Transform>(
          find.ancestor(of: title(), matching: find.byType(Transform)).first,
        )
        .transform
        .getTranslation()
        .y;

    testWidgets('the name rises into place as it fades in', (tester) async {
      await pumpFrame(tester);
      final page = tester.element(list);
      // The bar fades in over its own height, solid once the pager's box
      // passes under it.
      const barHeight = PdpTopBar.barHeight;
      final solidAt = PdpScaffoldView.solidAt(page);
      expect(
        solidAt,
        PdpScaffoldView.galleryHeight(page) -
            PdpSheet.overlap -
            MediaQuery.paddingOf(page).top -
            barHeight,
      );

      position(tester).jumpTo(solidAt - barHeight / 2);
      await tester.pump();
      expect(opacity(tester), moreOrLessEquals(0.5));
      expect(rise(tester), moreOrLessEquals(PdpTopBar.titleRise / 2));

      position(tester).jumpTo(solidAt + barHeight);
      await tester.pump();
      expect(opacity(tester), 1);
      expect(rise(tester), 0);
    });

    testWidgets('reduced motion: it fades in without rising', (tester) async {
      await pumpFrame(tester, reducedMotion: true);
      final solidAt = PdpScaffoldView.solidAt(tester.element(list));

      position(tester).jumpTo(solidAt - PdpTopBar.barHeight / 2);
      await tester.pump();
      expect(opacity(tester), moreOrLessEquals(0.5));
      expect(rise(tester), 0);
    });
  });

  group('photo flight', () {
    testWidgets('a tapped photo flies into the viewer and back to the page', (
      tester,
    ) async {
      await pumpFrame(tester);
      final heroes = find.byWidgetPredicate(
        (widget) =>
            widget is Hero && widget.tag == PdpPhoto.tagFor('milk', 'a.jpg', 0),
      );
      expect(heroes, findsOneWidget);

      await tester.tap(find.byType(PdpPhoto).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // In flight: the photo it left, scaled on the way.
      expect(find.byType(PdpPhotoFlight), findsOneWidget);
      await settle(tester);
      expect(find.byType(PdpPhotoFlight), findsNothing);
      expect(find.byType(PdpImageViewerPage), findsOneWidget);
      // The viewer's photo wears the same tag.
      expect(heroes, findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PdpPhotoFlight), findsOneWidget);
      await settle(tester);
      expect(find.byType(PdpImageViewerPage), findsNothing);
      expect(find.byType(PdpPhotoFlight), findsNothing);
    });

    testWidgets('another product page with the same photo never flies it', (
      tester,
    ) async {
      await pumpFrame(tester);

      unawaited(
        GoRouter.of(tester.element(find.byType(PdpScaffoldView)))
            .push(_otherProduct),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PdpPhotoFlight), findsNothing);
      await settle(tester);
      expect(
        find.byType(PdpScaffoldView, skipOffstage: false),
        findsNWidgets(2),
      );
    });

    testWidgets('reduced motion: the viewer opens without a flight', (
      tester,
    ) async {
      await pumpFrame(tester, reducedMotion: true);

      await tester.tap(find.byType(PdpPhoto).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PdpPhotoFlight), findsNothing);
      await settle(tester);
      expect(find.byType(PdpImageViewerPage), findsOneWidget);
    });
  });

  testWidgets('tags are flat grey chips, most telling first', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PdpTagChips(
            tags: [CatalogMerchTag.bestSeller, CatalogMerchTag.fresh],
          ),
        ),
      ),
    );

    final best = find.text('Best seller');
    final fresh = find.text('Fresh');
    expect(best, findsOneWidget);
    expect(fresh, findsOneWidget);
    expect(tester.getTopLeft(best).dx, lessThan(tester.getTopLeft(fresh).dx));
    final chip =
        tester
                .widget<DecoratedBox>(
                  find.ancestor(of: best, matching: find.byType(DecoratedBox)),
                )
                .decoration
            as BoxDecoration;
    expect(chip.color, AppColors.smallBackground);
  });
}
