// The catalogue rows the store and a category page are built from: the
// top-level tabs, the sub-category rail and the chips. Picking at one level
// re-scopes the levels below it and the product list with them.
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
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_chips.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_tab_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    slug: 'apples',
    name: 'Apples',
    parentId: 'c2',
  ),
  CatalogCategoryEntity(
    id: 'c4',
    slug: 'bananas',
    name: 'Bananas',
    parentId: 'c2',
  ),
  CatalogCategoryEntity(
    id: 'c9',
    slug: 'dairy-eggs',
    name: 'Dairy and Eggs',
    sortOrder: 1,
  ),
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

  /// The store's rows: tabs in the app bar, then the rail and the chips.
  Future<void> pumpRows(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<CategoryBrowseCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(
            appBar: CategoryTabBar(),
            body: Column(
              children: [CategoryRail(level: 1), CategoryChips(level: 2)],
            ),
          ),
        ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();
  }

  Finder inChips(String label) => find.descendant(
    of: find.byType(CategoryChips),
    matching: find.text(label),
  );

  Finder inRail(String label) => find.descendant(
    of: find.byType(CategoryRail),
    matching: find.text(label),
  );

  testWidgets('the store opens on its first tab and offers its subs', (
    tester,
  ) async {
    await pumpRows(tester);

    expect(find.text('Fresh Food'), findsOneWidget);
    expect(find.text('Dairy and Eggs'), findsOneWidget);
    // The rail of the open tab: "All" plus the one sub-category.
    expect(inRail('All'), findsOneWidget);
    expect(inRail('Fruits and Vegetables'), findsOneWidget);
    // Nothing is picked on the rail, so there are no chips yet.
    expect(inChips('All'), findsNothing);
    expect(cubit.state.browse.activeSlug, 'fresh-food');
  });

  testWidgets('a sub-category shows its chips and scopes the list', (
    tester,
  ) async {
    await pumpRows(tester);

    await tester.tap(inRail('Fruits and Vegetables'));
    await tester.pumpAndSettle();

    expect(cubit.state.browse.activeSlug, 'fruits-vegetables');
    expect(inChips('Apples'), findsOneWidget);
    expect(inChips('Bananas'), findsOneWidget);

    await tester.tap(inChips('Bananas'));
    await tester.pumpAndSettle();
    expect(cubit.state.browse.activeSlug, 'bananas');

    // "All" on the rail goes back to the whole tab, chips and all.
    await tester.tap(inRail('All'));
    await tester.pumpAndSettle();
    expect(cubit.state.browse.activeSlug, 'fresh-food');
    expect(inChips('Bananas'), findsNothing);
  });

  testWidgets('another tab drops the rows below it', (tester) async {
    await pumpRows(tester);
    await tester.tap(inRail('Fruits and Vegetables'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dairy and Eggs'));
    await tester.pumpAndSettle();

    expect(cubit.state.browse.activeSlug, 'dairy-eggs');
    expect(find.byType(CategoryRail), findsOneWidget); // present, but empty
    expect(inRail('All'), findsNothing);
    expect(inChips('Apples'), findsNothing);
  });
}
