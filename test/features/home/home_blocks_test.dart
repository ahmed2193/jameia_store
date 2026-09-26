// The home blocks the backend's data drives: a themed rail runs on a tinted
// band, a strip and its rail render as one campaign band, a stand-alone strip
// is a saturated band, and the category shelf scrolls in one or two rows.
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
import 'package:jameia_mart/src/features/home/domain/entities/home_link.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_arrow_button.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_category_grid.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_category_tile.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_product_rail.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_promo_strip.dart';
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
    testWidgets('a standard rail runs on the white page', (tester) async {
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
      expect(block.isTinted, isFalse);
      expect(block.fill, AppColors.white);
      expect(find.text('On sale now'), findsOneWidget);
    });

    testWidgets('a themed rail runs on a tinted band', (tester) async {
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
      expect(block.isTinted, isTrue);
      expect(block.fill, AppColors.finalPriceBg);
    });

    testWidgets('the arrow opens the collection behind the rail', (
      tester,
    ) async {
      var viewAll = 0;
      await pump(
        tester,
        HomeProductRail(
          section: _rail(theme: HomeSectionTheme.standard),
          onOpenProduct: (_) {},
          onViewAll: () => viewAll++,
        ),
      );

      expect(find.bySemanticsLabel('View all'), findsOneWidget);
      await tester.tap(find.byType(HomeArrowButton));
      expect(viewAll, 1);
    });

    testWidgets('a rail with nowhere to go has no arrow', (tester) async {
      await pump(
        tester,
        HomeProductRail(
          section: _rail(theme: HomeSectionTheme.standard, collectionSlug: ''),
          onOpenProduct: (_) {},
          onViewAll: () {},
        ),
      );

      expect(find.byType(HomeArrowButton), findsNothing);
      expect(find.text('On sale now'), findsOneWidget);
    });
  });

  group('HomeThemedBlock', () {
    testWidgets('the campaign heads its band, and its arrow opens it', (
      tester,
    ) async {
      var opened = 0;
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
          onOpenStrip: () => opened++,
          onOpenProduct: (_) {},
        ),
      );

      expect(find.text('Flash deals'), findsOneWidget);
      expect(find.text('Limited time'), findsOneWidget);
      // One heading per band: the campaign, not the rail's title under it.
      expect(find.text('On sale now'), findsNothing);
      final band = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(HomeThemedBlock),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(band.color, AppColors.accent3Light);

      await tester.tap(find.byType(HomeArrowButton));
      expect(opened, 1);
    });
  });

  group('HomePromoStrip', () {
    testWidgets('a strip that leads somewhere carries the arrow', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        HomePromoStrip(
          section: const HomePromoStripSection(
            id: 'strip',
            headline: 'Daily crazy deals',
            link: HomeLink(type: HomeLinkType.collection, target: 'daily'),
            theme: HomeSectionTheme.deals,
          ),
          onTap: () => opened++,
        ),
      );

      expect(find.text('Daily crazy deals'), findsOneWidget);
      await tester.tap(find.byType(HomeArrowButton));
      await tester.tap(find.text('Daily crazy deals'));
      expect(opened, 2);
    });

    testWidgets('a strip with no link is only a message', (tester) async {
      var opened = 0;
      await pump(
        tester,
        HomePromoStrip(
          section: const HomePromoStripSection(
            id: 'strip',
            headline: 'Free delivery all week',
            link: HomeLink.none,
          ),
          onTap: () => opened++,
        ),
      );

      expect(find.byType(HomeArrowButton), findsNothing);
      await tester.tap(find.text('Free delivery all week'));
      expect(opened, 0);
    });
  });

  group('HomeCategoryGrid', () {
    SliverGridDelegateWithFixedCrossAxisCount layoutOf(WidgetTester tester) =>
        tester.widget<GridView>(find.byType(GridView)).gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;

    testWidgets('a long shelf runs in two rows and reports the tapped aisle', (
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

      expect(layoutOf(tester).crossAxisCount, 2);
      expect(find.text('Shop by category'), findsOneWidget);

      await tester.tap(find.text('Category 0'));
      expect(opened?.slug, 'c0');
    });

    testWidgets('a short shelf is one row, and none renders nothing', (
      tester,
    ) async {
      await pump(
        tester,
        HomeCategoryGrid(
          section: HomeCategoryRailSection(
            id: 'cat',
            categories: _categories(HomeCategoryGrid.singleRowMax),
          ),
          onOpenCategory: (_) {},
          onViewAll: () {},
        ),
      );
      expect(layoutOf(tester).crossAxisCount, 1);
      expect(
        find.byType(HomeCategoryTile),
        findsNWidgets(HomeCategoryGrid.singleRowMax),
      );

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
