// The sub-category rail keeps the open circle in the middle: a pick far along
// the rail glides it there, so the next pick is always in reach.
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
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/shop/domain/usecases/watch_category_tree_usecase.dart';
import 'package:jameia_mart/src/features/shop/presentation/cubit/category_browse_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/browse/category_rail_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop_test_fakes.dart';

const int _subs = 12;

final List<CatalogCategoryEntity> _subCategories = [
  for (var i = 0; i < _subs; i++)
    CatalogCategoryEntity(
      id: 's$i',
      slug: 'sub-$i',
      name: 'Sub $i',
      parentId: 'c1',
      sortOrder: i,
    ),
];

final CatalogCategoryTree _tree = CatalogCategoryTree([
  const CatalogCategoryEntity(id: 'c1', slug: 'fresh', name: 'Fresh'),
  ..._subCategories,
]);

class _TreeRepository extends FakeCatalogBrowseRepository {
  @override
  Future<Either<Failure, CatalogCategoryTree>> getCategoryTree({
    bool refresh = false,
  }) async => Right(_tree);

  @override
  Future<Either<Failure, CatalogProductsPage>> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async => const Right(CatalogProductsPage.empty);
}

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

  testWidgets('a pick far along the rail glides to its middle', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = CategoryBrowseCubit(
      WatchCategoryTreeUseCase(_TreeRepository()),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<CategoryBrowseCubit>.value(
        value: cubit,
        child: const MaterialApp(home: Scaffold(body: CategoryRail(level: 1))),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();
    final rail = Scrollable.of(
      tester.element(find.byType(CategoryRailItem).first),
    ).position;
    expect(rail.pixels, 0, reason: '"All" is open: the rail starts at home');

    cubit.select(1, _subCategories[8]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(rail.isScrollingNotifier.value || rail.pixels > 0, isTrue);
    await tester.pumpAndSettle();

    final picked = tester.getCenter(
      find.widgetWithText(CategoryRailItem, 'Sub 8'),
    );
    expect(picked.dx, closeTo(390 / 2, 1), reason: 'in the middle');
  });
}
