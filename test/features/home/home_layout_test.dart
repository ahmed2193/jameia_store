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
import 'package:jameia_mart/src/features/home/presentation/widgets/home_category_tile.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_promo_cards.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The largest text the app lets through (`TextScalerClamp`).
const TextScaler _largestText = TextScaler.linear(1.3);

const CatalogProductEntity _product = CatalogProductEntity(
  id: 'p1',
  slug: 'bananas',
  name: 'Chiquita Bananas Premium Selection, 1kg',
  priceFils: 1250,
  compareAtFils: 1500,
  stock: 20,
  unitOfSale: UnitOfSale.kg,
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

  testWidgets('the loading skeleton fits the narrowest phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester, const HomeSkeleton());

    expect(tester.takeException(), isNull);
  });

  testWidgets('a product card fits the cell its rail gives it, scaled up', (
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
            child: CatalogProductCard(
              product: _product,
              qty: 0,
              onTap: () {},
              onAdd: () {},
              onRemove: () {},
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
  });

  testWidgets('the occasion cards fit their row, scaled up', (tester) async {
    await pump(
      tester,
      HomePromoCards(
        section: const HomePromoCardsSection(
          id: 'occasions',
          title: 'Shop by occasion',
          cards: [
            HomePromoCard(
              id: 'c1',
              title: 'Weeknight dinner',
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
    expect(find.text('Weeknight dinner'), findsOneWidget);
  });

  testWidgets('a category with no artwork still shows something', (
    tester,
  ) async {
    await pump(
      tester,
      SizedBox(
        height: HomeCategoryTile.height,
        child: HomeCategoryTile(
          category: const CatalogCategoryEntity(
            id: 'c1',
            slug: 'bakery',
            name: 'Bakery',
          ),
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.category_rounded), findsOneWidget);
  });

  testWidgets('the icon disc does not vanish into a tinted block', (
    tester,
  ) async {
    await pump(
      tester,
      const HomeSectionHeader(
        title: "Today's deals",
        icon: HomeIcon(key: HomeIconKey.trendingUp),
        accent: HomeAccent.amber,
        // The deals block is washed in the same amber the icon uses.
        fill: AppColors.accent3Light,
      ),
    );

    final disc = tester.widget<Container>(find.byType(Container).first);
    expect(
      (disc.decoration! as BoxDecoration).color,
      AppColors.white,
      reason: 'a disc the colour of its block is no disc at all',
    );
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
