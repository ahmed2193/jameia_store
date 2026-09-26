// The home blocks under pressure: the narrowest phone the app ships on and
// the largest text the app allows. Each of these was a real defect.
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
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/widgets/catalog_product_card.dart';
import 'package:jameia_mart/src/core/widgets/home_skeleton.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_icon.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_link.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_arrow_button.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_category_grid.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_category_tile.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_icon_view.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_min_order_bar.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_promo_cards.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The largest text the app lets through (`TextScalerClamp`).
const TextScaler _largestText = TextScaler.linear(1.3);

/// The tallest card a rail holds: a tag, two name lines, a unit, a deal
/// (price + struck price) and a Pro price.
const CatalogProductEntity _product = CatalogProductEntity(
  id: 'p1',
  slug: 'bananas',
  name: 'Chiquita Bananas Premium Selection, 1kg',
  priceFils: 1250,
  compareAtFils: 1500,
  proPriceFils: 1100,
  stock: 20,
  unitOfSale: UnitOfSale.kg,
  tags: ['best-seller'],
  ratingAverage: 4.5,
  ratingCount: 12,
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

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );

  void narrowestPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('the loading skeleton fits the narrowest phone', (tester) async {
    narrowestPhone(tester);

    await pump(tester, const HomeSkeleton());

    expect(tester.takeException(), isNull);
  });

  testWidgets('at rest a product cell is the picture plus the text block', (
    tester,
  ) async {
    late double cell;
    await pump(
      tester,
      Builder(
        builder: (context) {
          cell = CatalogProductCard.cellHeight(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(
      cell,
      CatalogProductCard.defaultWidth + CatalogProductCard.textBlockHeight,
    );
  });

  testWidgets('a product card fits the cell its rail gives it, scaled up', (
    tester,
  ) async {
    narrowestPhone(tester);
    late double cell;
    await pump(
      tester,
      Builder(
        builder: (context) {
          cell = CatalogProductCard.cellHeight(context);
          return SizedBox(
            width: CatalogProductCard.defaultWidth,
            height: cell,
            // Free of the cell's tight height, so the card lays out at its
            // own height (spilling past the cell still reports).
            child: UnconstrainedBox(
              alignment: AlignmentDirectional.topStart,
              constrainedAxis: Axis.horizontal,
              child: CatalogProductCard(
                product: _product,
                qty: 0,
                onTap: () {},
                onAdd: () {},
                onRemove: () {},
              ),
            ),
          );
        },
      ),
      textScaler: _largestText,
    );

    expect(tester.takeException(), isNull);
    // The cell grew with the text; at rest it is the plain card height.
    expect(
      cell,
      greaterThan(
        CatalogProductCard.defaultWidth + CatalogProductCard.textBlockHeight,
      ),
    );
    // The card's own height (every line of the tallest card), not the cell's.
    final height = tester.getSize(find.byType(CatalogProductCard)).height;
    expect(height, lessThanOrEqualTo(cell));
    expect(height, greaterThan(CatalogProductCard.defaultWidth));
  });

  testWidgets('a plain card is shorter than its cell: the room is spare', (
    tester,
  ) async {
    late double cell;
    await pump(
      tester,
      Builder(
        builder: (context) {
          cell = CatalogProductCard.cellHeight(context);
          return SizedBox(
            width: CatalogProductCard.defaultWidth,
            height: cell,
            child: UnconstrainedBox(
              alignment: AlignmentDirectional.topStart,
              constrainedAxis: Axis.horizontal,
              child: CatalogProductCard(
                product: const CatalogProductEntity(
                  id: 'p2',
                  slug: 'lemon',
                  name: 'Lemon',
                  priceFils: 500,
                  stock: 5,
                ),
                qty: 0,
                onTap: () {},
                onAdd: () {},
                onRemove: () {},
              ),
            ),
          );
        },
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CatalogProductCard)).height,
      lessThan(cell),
    );
  });

  testWidgets('the occasion tiles fit their row, scaled up', (tester) async {
    await pump(
      tester,
      HomePromoCards(
        section: const HomePromoCardsSection(
          id: 'occasions',
          title: 'Shop by occasion',
          cards: [
            HomePromoCard(
              id: 'c1',
              title: 'Weeknight dinner for the whole family',
              subtitle: 'Ready in 20 minutes',
              link: HomeLink(type: HomeLinkType.collection, target: 'dinner'),
              accent: HomeAccent.violet,
            ),
          ],
        ),
        onOpenLink: (_, _) {},
      ),
      textScaler: _largestText,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Weeknight dinner for the whole family'), findsOneWidget);
  });

  testWidgets('both rows of the category shelf fit, scaled up', (tester) async {
    await pump(
      tester,
      SingleChildScrollView(
        child: HomeCategoryGrid(
          section: HomeCategoryRailSection(
            id: 'cat',
            title: 'Shop by category',
            categories: [
              for (var i = 0; i < 12; i++)
                CatalogCategoryEntity(
                  id: 'c$i',
                  slug: 'c$i',
                  name: 'Fruits, vegetables and fresh herbs $i',
                ),
            ],
          ),
          onOpenCategory: (_) {},
          onViewAll: () {},
        ),
      ),
      textScaler: _largestText,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a category with no artwork still shows something', (
    tester,
  ) async {
    await pump(
      tester,
      Builder(
        builder: (context) => SizedBox(
          height: HomeCategoryTile.cellHeight(context),
          child: HomeCategoryTile(
            category: const CatalogCategoryEntity(
              id: 'c1',
              slug: 'bakery',
              name: 'Bakery',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.category_rounded), findsOneWidget);
  });

  testWidgets('a header wears the backend icon in its accent', (tester) async {
    await pump(
      tester,
      const HomeSectionHeader(
        title: "Today's deals",
        icon: HomeIcon(key: HomeIconKey.trendingUp),
        accent: HomeAccent.amber,
      ),
    );

    expect(
      tester.widget<HomeIconView>(find.byType(HomeIconView)).color,
      AppColors.accent3,
    );
    // Nowhere to go: no arrow.
    expect(find.byType(HomeArrowButton), findsNothing);
  });

  testWidgets('the minimum-order bar fits the narrowest phone, scaled up', (
    tester,
  ) async {
    narrowestPhone(tester);

    await pump(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: HomeMinOrderBar(
          message: 'Start adding KD 12.500 to place your order!',
          onInfo: () {},
        ),
      ),
      textScaler: _largestText,
    );

    expect(tester.takeException(), isNull);
  });

  group('HomeDelivery', () {
    const delivery = HomeDelivery(minOrderFils: 3500);

    test('a basket that meets the minimum exactly is not short', () {
      // 3.500 as a double is not exactly 3.5 once summed from line totals.
      expect(delivery.shortfallFils(1.75 + 1.75), 0);
      expect(delivery.shortfallFils(3.5), 0);
      expect(delivery.shortfallFils(4), 0);
    });

    test('a basket below the minimum reports the gap in fils', () {
      expect(delivery.shortfallFils(3.25), 250);
      expect(delivery.shortfallKd(3.25), 0.25);
    });
  });
}
