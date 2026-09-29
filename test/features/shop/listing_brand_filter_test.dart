// B3-02: the listing's brand filter opens its sheet at once and fills it in as
// the brand list arrives — no silent wait on the pill — and a second tap while
// the read runs is absorbed: never a second, empty "no brands" sheet.
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
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/domain/entities/brand_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/usecase/watch_params.dart';
import 'package:hero_mart/src/core/widgets/app_loader.dart';
import 'package:hero_mart/src/features/shop/domain/usecases/get_products_usecase.dart';
import 'package:hero_mart/src/features/shop/domain/usecases/watch_brands_usecase.dart';
import 'package:hero_mart/src/features/shop/presentation/cubit/product_listing_cubit.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/listing/listing_brand_sheet.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/listing/listing_toolbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop_test_fakes.dart';

/// Never answers: the listing itself stays loading.
class _SilentGetProducts implements GetProductsUseCase {
  @override
  Future<Either<Failure, CatalogProductsPage>> call(GetProductsParams params) =>
      Completer<Either<Failure, CatalogProductsPage>>().future;
}

/// The brand list, answered when the test says so; counts the reads.
class _GatedBrands implements WatchBrandsUseCase {
  final Completer<Either<Failure, List<BrandEntity>>> answer =
      Completer<Either<Failure, List<BrandEntity>>>();
  int calls = 0;

  @override
  Stream<DataSnapshot<List<BrandEntity>>> call(WatchParams params) {
    calls++;
    return networkRead(answer.future);
  }
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

  /// The toolbar over [cubit], under a router (the sheet pops through it).
  Future<void> pumpToolbar(
    WidgetTester tester,
    ProductListingCubit cubit,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider<ProductListingCubit>.value(
              value: cubit,
              child: const ListingToolbar(),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('the sheet opens at once, a double tap stays one sheet, and '
      'the brands fill it in', (tester) async {
    final brands = _GatedBrands();
    final products = _SilentGetProducts();
    final cubit = ProductListingCubit(
      WatchProductsFromGet(products),
      products,
      brands,
      query: const CatalogProductQuery(categorySlug: 'fresh-food'),
    );
    addTearDown(cubit.close);
    await pumpToolbar(tester, cubit);

    final pill = find.text('Brand');
    await tester.tap(pill);
    await tester.tap(pill, warnIfMissed: false); // the double tap
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ListingBrandSheet), findsOneWidget, reason: 'at once');
    expect(find.byType(AppLoader), findsOneWidget, reason: 'the read runs');
    expect(find.text('No brands yet'), findsNothing);
    expect(brands.calls, 1);

    brands.answer.complete(
      const Right([
        BrandEntity(id: 'b1', slug: 'almarai', name: 'Almarai'),
        BrandEntity(id: 'b2', slug: 'kdd', name: 'KDD'),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ListingBrandSheet), findsOneWidget);
    expect(find.text('Almarai'), findsOneWidget);
    expect(find.text('All brands'), findsOneWidget);
    expect(find.text('No brands yet'), findsNothing);

    await tester.tap(find.text('Almarai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ListingBrandSheet), findsNothing);
    expect(cubit.state.query.brandSlug, 'almarai');

    // Opened again: the list is there already, no second read.
    await tester.tap(find.text('Almarai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('KDD'), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
    expect(brands.calls, 1);
  });

  testWidgets('a failed read with nothing saved says there are no brands', (
    tester,
  ) async {
    final brands = _GatedBrands();
    final products = _SilentGetProducts();
    final cubit = ProductListingCubit(
      WatchProductsFromGet(products),
      products,
      brands,
      query: const CatalogProductQuery(categorySlug: 'fresh-food'),
    );
    addTearDown(cubit.close);
    await pumpToolbar(tester, cubit);

    await tester.tap(find.text('Brand'));
    await tester.pump();
    brands.answer.complete(const Left(NetworkFailure()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ListingBrandSheet), findsOneWidget);
    expect(find.text('No brands yet'), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
  });
}
