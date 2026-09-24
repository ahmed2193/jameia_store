// The home blocks the backend's data drives: a themed rail becomes a tinted
// inset card, a strip and its rail render as one block, and the category grid
// pages through the store's aisles.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/config/theme/app_colors.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/widgets/paging_dots.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_link.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_category_grid.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_category_tile.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_product_rail.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_section_block.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_themed_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

HomeProductRailSection _rail({
  required HomeSectionTheme theme,
  String title = 'On sale now',
  String collectionSlug = 'on-sale',
}) => HomeProductRailSection(
  id: 'rail',
  products: const [],
  title: title,
  theme: theme,
  collectionSlug: collectionSlug,
);

List<CatalogCategoryEntity> _categories(int count) => [
  for (var i = 0; i < count; i++)
    CatalogCategoryEntity(id: 'c$i', slug: 'c$i', name: 'Category $i'),
];

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

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  group('HomeProductRail', () {
    testWidgets('a standard rail is a full-bleed white band', (tester) async {
      await pump(
        tester,
        HomeProductRail(
          section: _rail(theme: HomeSectionTheme.standard),
          onOpenProduct: (_) {},
          onViewAll: () {},
        ),
      );

      final block = tester.widget<HomeSectionBlock>(
        find.byType(HomeSectionBlock),
      );
      expect(block.inset, isFalse);
      expect(block.fill, AppColors.white);
      expect(find.text('On sale now'), findsOneWidget);
    });

    testWidgets('a themed rail is a tinted card inset from the page', (
      tester,
    ) async {
      await pump(
        tester,
        HomeProductRail(
          section: _rail(theme: HomeSectionTheme.sale),
          onOpenProduct: (_) {},
          onViewAll: () {},
        ),
      );

      final block = tester.widget<HomeSectionBlock>(
        find.byType(HomeSectionBlock),
      );
      expect(block.inset, isTrue);
      expect(block.fill, AppColors.finalPriceBg);
    });

    testWidgets('a rail with nowhere to go has no "view all"', (tester) async {
      await pump(
        tester,
        HomeProductRail(
          section: _rail(theme: HomeSectionTheme.standard, collectionSlug: ''),
          onOpenProduct: (_) {},
          onViewAll: () {},
        ),
      );

      expect(find.text('View all'), findsNothing);
      expect(find.text('On sale now'), findsOneWidget);
    });
  });

  group('HomeThemedBlock', () {
    testWidgets('shows the call-out over the rail it advertises', (
      tester,
    ) async {
      final block = HomeThemedBlockSection(
        strip: const HomePromoStripSection(
          id: 'strip',
          headline: 'Flash deals',
          badge: 'Limited time',
          link: HomeLink(type: HomeLinkType.collection, target: 'on-sale'),
          theme: HomeSectionTheme.deals,
        ),
        rail: _rail(theme: HomeSectionTheme.deals),
      );

      await pump(
        tester,
        HomeThemedBlock(
          section: block,
          onOpenStrip: () {},
          onOpenProduct: (_) {},
          onViewAll: () {},
        ),
      );

      expect(find.text('Flash deals'), findsOneWidget);
      expect(find.text('Limited time'), findsOneWidget);
      expect(find.text('On sale now'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
      final container = tester.widget<HomeSectionBlock>(
        find.byType(HomeSectionBlock),
      );
      expect(container.inset, isTrue);
      expect(container.fill, AppColors.accent3Light);
    });
  });

  group('HomeCategoryGrid', () {
    testWidgets('pages the categories and reports the tapped one', (
      tester,
    ) async {
      CatalogCategoryEntity? opened;
      await pump(
        tester,
        HomeCategoryGrid(
          section: HomeCategoryRailSection(
            id: 'cat',
            title: 'Shop by category',
            categories: _categories(13),
          ),
          onOpenCategory: (category) => opened = category,
          onViewAll: () {},
        ),
      );

      // 13 categories = 12 on the first page + 1 on the second, and the
      // second page peeks, so both are built.
      expect(tester.widget<PagingDots>(find.byType(PagingDots)).count, 2);
      expect(find.byType(HomeCategoryTile), findsNWidgets(13));

      await tester.tap(find.text('Category 0'));
      expect(opened?.slug, 'c0');
    });

    testWidgets('a single page has no dots, and none at all renders nothing', (
      tester,
    ) async {
      await pump(
        tester,
        HomeCategoryGrid(
          section: HomeCategoryRailSection(
            id: 'cat',
            categories: _categories(4),
          ),
          onOpenCategory: (_) {},
          onViewAll: () {},
        ),
      );
      expect(find.byType(HomeCategoryTile), findsNWidgets(4));
      expect(find.byType(PagingDots), findsNothing);

      await pump(
        tester,
        HomeCategoryGrid(
          section: const HomeCategoryRailSection(id: 'cat', categories: []),
          onOpenCategory: (_) {},
          onViewAll: () {},
        ),
      );
      expect(find.byType(HomeCategoryTile), findsNothing);
      expect(find.byType(HomeSectionBlock), findsNothing);
    });
  });
}
