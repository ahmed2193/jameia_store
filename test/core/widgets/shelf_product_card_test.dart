// The talabat-style listing card: the "Save" badge and the struck price on a
// deal, the lime marker that draws itself under the price as the card lands,
// the merchandising tag, what a Pro member would pay, and the round "+" that
// grows into the quantity stepper.
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
import 'package:jameia_mart/src/config/theme/app_text_styles.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/widgets/catalog_pill_stepper.dart';
import 'package:jameia_mart/src/core/widgets/shelf_add_button.dart';
import 'package:jameia_mart/src/core/widgets/shelf_card_media.dart';
import 'package:jameia_mart/src/core/widgets/shelf_marker_painter.dart';
import 'package:jameia_mart/src/core/widgets/shelf_product_card.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/listing/listing_reveal.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/listing/listing_reveal_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

const CatalogProductEntity _turkey = CatalogProductEntity(
  id: 'p1',
  slug: 'smoked-turkey',
  name: 'Smoked Turkey, 250g',
  priceFils: 1000,
  compareAtFils: 1250,
  proPriceFils: 900,
  stock: 5,
  tags: ['best-seller'],
);

const CatalogProductEntity _lemon = CatalogProductEntity(
  id: 'p2',
  slug: 'lemon',
  name: 'Lemon, 500g',
  priceFils: 500,
  stock: 5,
  tags: ['fresh'],
);

const double _width = 170;
const Duration _clock = Duration(milliseconds: 900);

/// Anything drawn with a hairline outline.
final Finder _outlined = find.byWidgetPredicate((widget) {
  final decoration = switch (widget) {
    DecoratedBox(:final decoration) => decoration,
    Container(:final decoration?) => decoration,
    _ => null,
  };
  return decoration is BoxDecoration && decoration.border != null;
});

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

  Widget card(CatalogProductEntity product, {int qty = 0, bool pro = false}) =>
      ShelfProductCard(
        product: product,
        qty: qty,
        pro: pro,
        width: _width,
        onTap: () {},
        onAdd: () {},
        onRemove: () {},
      );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: Center(child: child)),
      ),
    ),
  );

  testWidgets('a deal wears its saving, the struck price and a tag', (
    tester,
  ) async {
    await pump(tester, card(_turkey));

    expect(find.text('Save 20%'), findsOneWidget);
    expect(find.text('1.000'), findsOneWidget, reason: 'the price');
    expect(find.text('KD 1.250'), findsOneWidget, reason: 'the "was" price');
    expect(find.text('Best seller'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is ShelfMarkerPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the struck "was" price sits on its own line under the price', (
    tester,
  ) async {
    await pump(tester, card(_turkey));

    final price = tester.getRect(find.text('1.000'));
    final was = tester.getRect(find.text('KD 1.250'));
    expect(was.top, greaterThanOrEqualTo(price.bottom));
    // Both lines start at the card's start edge.
    expect(was.left, closeTo(tester.getRect(find.text('KD')).left, 0.01));
    expect(
      tester.widget<Text>(find.text('KD 1.250')).style!.decoration,
      TextDecoration.lineThrough,
    );
    // The price reads in a medium weight, not a heavy one.
    expect(
      tester.widget<Text>(find.text('1.000')).style!.fontWeight,
      AppTextStyles.medium,
    );
  });

  testWidgets('the picture sits on a light-grey tile with no outline', (
    tester,
  ) async {
    await pump(tester, card(_lemon));

    final media = find.byType(ShelfCardMedia);
    final grey = find.descendant(
      of: media,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == AppColors.smallBackground,
      ),
    );
    expect(grey, findsWidgets);
    expect(tester.getSize(grey.first), const Size.square(_width));
    expect(find.descendant(of: media, matching: _outlined), findsNothing);
    // The round "+" rides the bottom-end corner, inset from it.
    final tile = tester.getRect(media);
    final add = tester.getRect(find.byType(ShelfAddButton));
    expect(add.right, tile.right - ShelfCardMedia.controlInset);
    expect(add.bottom, tile.bottom - ShelfCardMedia.controlInset);
  });

  testWidgets('a product sold in sizes, or as a bundle, says so', (
    tester,
  ) async {
    await pump(
      tester,
      card(
        const CatalogProductEntity(
          id: 'p4',
          slug: 'cola',
          name: 'Cola',
          type: CatalogProductType.variant,
          stock: 5,
        ),
      ),
    );
    expect(find.text('Multiple sizes'), findsOneWidget);

    await pump(
      tester,
      card(
        const CatalogProductEntity(
          id: 'p5',
          slug: 'breakfast',
          name: 'Breakfast box',
          type: CatalogProductType.bundle,
          priceFils: 2500,
          stock: 5,
        ),
      ),
    );
    expect(find.text('Bundle'), findsOneWidget);

    // The unit it is sold by comes first.
    await pump(
      tester,
      card(
        const CatalogProductEntity(
          id: 'p6',
          slug: 'grapes',
          name: 'Grapes',
          type: CatalogProductType.variant,
          unitOfSale: UnitOfSale.kg,
          stock: 5,
        ),
      ),
    );
    expect(find.text('per kg'), findsOneWidget);
    expect(find.text('Multiple sizes'), findsNothing);
  });

  testWidgets('a plain price has no badge and no marker', (tester) async {
    await pump(tester, card(_lemon));

    expect(find.textContaining('Save'), findsNothing);
    expect(find.text('Fresh'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is ShelfMarkerPainter,
      ),
      findsNothing,
    );
  });

  testWidgets('what a Pro member would pay, for everyone else', (tester) async {
    await pump(tester, card(_turkey));
    expect(find.text('pro'), findsOneWidget);

    await pump(tester, card(_turkey, pro: true));
    expect(find.text('pro'), findsNothing, reason: 'a member sees it as price');
    expect(find.text('0.900'), findsOneWidget);
  });

  testWidgets('the round + grows into the stepper once in the basket', (
    tester,
  ) async {
    await pump(tester, card(_lemon));
    expect(find.byType(ShelfAddButton), findsOneWidget);
    expect(find.byType(CatalogPillStepper), findsNothing);

    await pump(tester, card(_lemon, qty: 2));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CatalogPillStepper), findsOneWidget, reason: 'growing');

    await tester.pumpAndSettle();
    expect(find.byType(ShelfAddButton), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('out of stock: no basket control', (tester) async {
    await pump(
      tester,
      card(
        const CatalogProductEntity(
          id: 'p3',
          slug: 'gone',
          name: 'Gone',
          priceFils: 100,
        ),
      ),
    );
    expect(find.byType(ShelfAddButton), findsNothing);
  });

  testWidgets('the marker draws itself in as the card lands', (tester) async {
    Widget landing(bool settled) => ListingReveal(
      settled: settled,
      child: ListingRevealItem(index: 0, child: card(_turkey)),
    );
    double drawn() =>
        (tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.painter is ShelfMarkerPainter,
                      ),
                    )
                    .painter!
                as ShelfMarkerPainter)
            .progress
            .value;

    await pump(tester, landing(false));
    expect(drawn(), 0);

    await pump(tester, landing(true));
    await tester.pump();
    await tester.pump(_clock);
    expect(drawn(), 1);
  });
}
