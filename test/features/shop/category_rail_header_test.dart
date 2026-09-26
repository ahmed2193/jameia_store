// The sub-category rail on top of a listing never scrolls away: circles at
// rest, folded into a row of chips while the products scroll under it,
// unfolded again as soon as the customer scrolls back up. A pick from the
// chips takes the new list back to its top.
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
import 'package:jameia_mart/src/core/domain/entities/brand_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/shop/domain/repositories/catalog_browse_repository.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/get_category_tree_usecase.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/category_browse_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail_chip.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail_header.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail_header_delegate.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

const CatalogCategoryEntity _dairy = CatalogCategoryEntity(
  id: 'c9',
  slug: 'dairy-eggs',
  name: 'Dairy and Eggs',
  sortOrder: 1,
);

final CatalogCategoryTree _tree = CatalogCategoryTree(const [
  CatalogCategoryEntity(id: 'c1', slug: 'fresh-food', name: 'Fresh Food'),
  CatalogCategoryEntity(
    id: 'c2',
    slug: 'fruits-vegetables',
    name: 'Fruits and Vegetables',
    parentId: 'c1',
  ),
  CatalogCategoryEntity(
    id: 'c3',
    slug: 'herbs',
    name: 'Herbs',
    parentId: 'c1',
    sortOrder: 1,
  ),
  _dairy,
]);

class _TreeRepository implements CatalogBrowseRepository {
  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  }) async => Right(_tree);

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async =>
      const Right(<BrandEntity>[]);

  @override
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async => const Right(CatalogProductsPage.empty);
}

const double _row = 100;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryBrowseCubit cubit;

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
    cubit = CategoryBrowseCubit(GetCategoryTreeUseCase(_TreeRepository()));
  });

  tearDown(() => cubit.close());

  /// A listing: the rail of the store's open tab over a long list.
  Future<void> pumpListing(
    WidgetTester tester, {
    bool reducedMotion = false,
  }) async {
    await tester.pumpWidget(
      BlocProvider<CategoryBrowseCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reducedMotion),
              child: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    const CategoryRailHeader(level: 1),
                    SliverList.builder(
                      itemCount: 40,
                      itemBuilder: (_, index) =>
                          SizedBox(height: _row, child: Text('Row $index')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();
  }

  Finder circles() => find.byType(CategoryRailItem).hitTestable();
  Finder chips() => find.byType(CategoryRailChip).hitTestable();
  Finder header() => find
      .descendant(
        of: find.byType(CategoryRailHeader),
        matching: find.byType(DecoratedBox),
      )
      .first;
  ScrollPosition list(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      )
      .position;

  /// Drags the list the way a finger does, a frame at a time (a floating
  /// header only unfolds while it sees the finger moving).
  Future<void> scrollBy(WidgetTester tester, double dy) async {
    const steps = 10;
    final finger = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    for (var step = 0; step < steps; step++) {
      await finger.moveBy(Offset(0, dy / steps));
      await tester.pump();
    }
    await finger.up();
    await tester.pumpAndSettle();
  }

  testWidgets('at rest the rail is circles, picture above the name', (
    tester,
  ) async {
    await pumpListing(tester);

    expect(circles(), findsNWidgets(3), reason: 'All + two subs');
    expect(chips(), findsNothing);
    expect(tester.getSize(header()).height, CategoryRail.height);
  });

  testWidgets('scrolled, it folds into a row of chips that stays on top', (
    tester,
  ) async {
    await pumpListing(tester);

    await scrollBy(tester, -_row * 6);

    expect(list(tester).pixels, greaterThan(_row * 5));
    expect(chips(), findsNWidgets(3));
    expect(circles(), findsNothing);
    expect(
      tester.getSize(header()).height,
      CategoryRailHeaderDelegate.foldedHeight,
    );
    expect(tester.getTopLeft(header()).dy, 0, reason: 'pinned');
  });

  testWidgets('scrolling back up unfolds the circles again', (tester) async {
    await pumpListing(tester);
    await scrollBy(tester, -_row * 10);
    expect(chips(), findsNWidgets(3));

    await scrollBy(tester, _row * 2);

    expect(list(tester).pixels, greaterThan(0), reason: 'mid-list');
    expect(circles(), findsNWidgets(3));
    expect(chips(), findsNothing);
  });

  testWidgets('a pick from the chips scopes the list and goes to the top', (
    tester,
  ) async {
    await pumpListing(tester);
    await scrollBy(tester, -_row * 10);

    await tester.tap(
      find.descendant(
        of: find.byType(CategoryRailChip),
        matching: find.text('Herbs'),
      ),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.browse.activeSlug, 'herbs');
    expect(list(tester).pixels, 0);
    expect(circles(), findsNWidgets(3));
  });

  testWidgets('with reduced motion the rows swap instead of cross-fading', (
    tester,
  ) async {
    await pumpListing(tester, reducedMotion: true);
    double railOpacity() => tester
        .widget<Opacity>(
          find.ancestor(
            of: find.byType(CategoryRail),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    const range = CategoryRail.height - CategoryRailHeaderDelegate.foldedHeight;

    list(tester).jumpTo(range * 0.3);
    await tester.pump();
    expect(railOpacity(), 1);

    list(tester).jumpTo(range * 0.7);
    await tester.pump();
    expect(railOpacity(), 0);
  });

  testWidgets('a category with no subs takes no room', (tester) async {
    await pumpListing(tester);

    cubit.select(0, _dairy);
    await tester.pumpAndSettle();

    expect(find.byType(SliverPersistentHeader), findsNothing);
    expect(find.byType(CategoryRailItem), findsNothing);
    expect(tester.getTopLeft(find.text('Row 0')).dy, 0);
  });
}
