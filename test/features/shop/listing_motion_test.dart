// How a product listing moves: shimmering card bones while it loads, then the
// count and the first cards come in one after another as the listing FIRST
// arrives (EntranceCascade) — never again while scrolling, nor for a new sort
// or filter — and not at all under reduced motion.
import 'dart:async';
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
import 'package:hero_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade_item.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/state_views.dart';
import 'package:hero_mart/src/features/shop/domain/usecases/get_products_usecase.dart';
import 'package:hero_mart/src/features/shop/presentation/cubit/product_listing_cubit.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/listing/listing_grid_skeleton.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/listing/listing_skeleton_card.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/listing/product_listing_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop_test_fakes.dart';

/// Answers each product request only when the test says so.
class _GatedGetProducts implements GetProductsUseCase {
  final List<Completer<Either<Failure, CatalogProductsPage>>> calls = [];

  @override
  Future<Either<Failure, CatalogProductsPage>> call(GetProductsParams params) {
    final completer = Completer<Either<Failure, CatalogProductsPage>>();
    calls.add(completer);
    return completer.future;
  }
}

/// Stands in for a card: something with a size to fade.
class _Piece extends StatelessWidget {
  const _Piece(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 40, child: Text(label));
}

/// Long enough for the last cascading piece to land.
const Duration _clock = Duration(milliseconds: 500);

/// The listing's own fades (the route has fades of its own).
final Finder _listingFade = find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is EntranceCascade || widget is ProductListingBody,
  ),
  matching: find.byType(FadeTransition),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  Widget app(Widget child, {bool reducedMotion = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: Scaffold(body: child),
      ),
    ),
  );

  double opacityOf(WidgetTester tester, String label) {
    final fade = find.ancestor(of: find.text(label), matching: _listingFade);
    if (fade.evaluate().isEmpty) return 1;
    return tester.widget<FadeTransition>(fade.first).opacity.value;
  }

  // The pieces mount with the list (a loading listing shows bones instead).
  Widget pieces({required bool settled, int count = 3}) => EntranceCascade(
    ready: settled,
    child: Column(
      children: [
        if (settled)
          for (var i = 0; i < count; i++)
            EntranceCascadeItem(index: i, child: _Piece('Piece $i')),
      ],
    ),
  );

  group('the listing entrance', () {
    testWidgets('the pieces come in one after another as the list arrives', (
      tester,
    ) async {
      await tester.pumpWidget(app(pieces(settled: false)));
      expect(find.text('Piece 0'), findsNothing, reason: 'waiting');

      await tester.pumpWidget(app(pieces(settled: true)));
      await tester.pump();
      await tester.pump(_clock * 0.2);
      expect(opacityOf(tester, 'Piece 0'), greaterThan(0));
      expect(
        opacityOf(tester, 'Piece 2'),
        lessThan(opacityOf(tester, 'Piece 0')),
        reason: 'a beat behind',
      );

      await tester.pump(_clock);
      expect(opacityOf(tester, 'Piece 0'), 1);
      expect(opacityOf(tester, 'Piece 2'), 1);
    });

    testWidgets('only the first pieces take part', (tester) async {
      await tester.pumpWidget(
        app(pieces(settled: true, count: AppMotion.staggerMaxItems + 1)),
      );
      expect(opacityOf(tester, 'Piece 0'), 0);
      expect(
        find.ancestor(
          of: find.text('Piece ${AppMotion.staggerMaxItems}'),
          matching: _listingFade,
        ),
        findsNothing,
      );
      await tester.pump(_clock);
    });

    testWidgets('a piece built again later does not replay', (tester) async {
      await tester.pumpWidget(app(pieces(settled: true, count: 1)));
      await tester.pump();
      await tester.pump(_clock * 2);
      expect(opacityOf(tester, 'Piece 0'), 1);

      // Scrolled away and back: a fresh element under the spent scope.
      await tester.pumpWidget(app(pieces(settled: true, count: 0)));
      await tester.pumpWidget(app(pieces(settled: true, count: 1)));
      expect(opacityOf(tester, 'Piece 0'), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a new sort or filter swaps the cards in place: no replay', (
      tester,
    ) async {
      await tester.pumpWidget(app(pieces(settled: true)));
      await tester.pump();
      await tester.pump(_clock * 2);

      await tester.pumpWidget(app(pieces(settled: false)));
      await tester.pumpWidget(app(pieces(settled: true)));
      await tester.pump();
      expect(opacityOf(tester, 'Piece 0'), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('under reduced motion everything is simply there', (
      tester,
    ) async {
      await tester.pumpWidget(app(pieces(settled: true), reducedMotion: true));
      await tester.pump();
      expect(opacityOf(tester, 'Piece 0'), 1);
      expect(opacityOf(tester, 'Piece 2'), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('the loading bones follow the grid columns', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(const SingleChildScrollView(child: ListingGridSkeleton())),
    );
    expect(find.byType(ListingSkeletonCard), findsNWidgets(4), reason: '2×2');

    tester.view.physicalSize = const Size(800, 800);
    await tester.pumpWidget(
      app(const SingleChildScrollView(child: ListingGridSkeleton())),
    );
    expect(find.byType(ListingSkeletonCard), findsNWidgets(8), reason: '4×2');
  });

  testWidgets('a listing shows bones, then its empty view comes in', (
    tester,
  ) async {
    final products = _GatedGetProducts();
    final cubit = ProductListingCubit(
      WatchProductsFromGet(products),
      products,
      NoBrands(),
      query: const CatalogProductQuery(categorySlug: 'fresh-food'),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      app(
        BlocProvider<ProductListingCubit>.value(
          value: cubit,
          child: const ProductListingBody(),
        ),
      ),
    );
    unawaited(cubit.load());
    await tester.pump();
    expect(find.byType(ListingGridSkeleton), findsOneWidget);

    products.calls.single.complete(const Right(CatalogProductsPage.empty));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ListingGridSkeleton), findsNothing);
    final fade = find.ancestor(
      of: find.byType(EmptyStateView),
      matching: _listingFade,
    );
    expect(
      tester.widget<FadeTransition>(fade.first).opacity.value,
      lessThan(1),
    );

    await tester.pump(_clock * 2);
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
  });
}
