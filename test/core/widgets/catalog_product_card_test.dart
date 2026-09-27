// The app-wide product card of the home rails and the assistant: the same
// Hero shelf card as the listing grid — a light-grey picture tile with no
// outline, the lime "Save" badge and the round "+", the name, the unit (or
// what kind of product it is), the price with its marker and the struck
// "was" price on its own line — sized by the rail from one cell height.
import 'dart:convert';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/config/theme/app_spacing.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/widgets/catalog_discount_badge.dart';
import 'package:hero_mart/src/core/widgets/catalog_pill_stepper.dart';
import 'package:hero_mart/src/core/widgets/catalog_product_card.dart';
import 'package:hero_mart/src/core/widgets/rating_badge.dart';
import 'package:hero_mart/src/core/widgets/shelf_add_button.dart';
import 'package:hero_mart/src/core/widgets/shelf_card_media.dart';
import 'package:hero_mart/src/core/widgets/shelf_card_price.dart';
import 'package:hero_mart/src/core/widgets/shelf_marker_painter.dart';
import 'package:hero_mart/src/core/widgets/shelf_product_card.dart';
import 'package:hero_mart/src/core/widgets/shelf_save_badge.dart';
import 'package:hero_mart/src/core/widgets/shelf_tag_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything a card can carry at once: a tag, a long name, a unit, a deal
/// and a Pro price — the tallest card a rail must fit.
const CatalogProductEntity _deal = CatalogProductEntity(
  id: 'p1',
  slug: 'smoked-turkey',
  name: 'Smoked Turkey Breast Slices, Family Value Pack 250g',
  priceFils: 1000,
  compareAtFils: 1250,
  proPriceFils: 900,
  stock: 5,
  unitOfSale: UnitOfSale.pack,
  tags: ['best-seller'],
  ratingAverage: 4.5,
  ratingCount: 12,
);

const CatalogProductEntity _lemon = CatalogProductEntity(
  id: 'p2',
  slug: 'lemon',
  name: 'Lemon',
  priceFils: 500,
  stock: 5,
  ratingAverage: 4.8,
  ratingCount: 30,
);

const CatalogProductEntity _cola = CatalogProductEntity(
  id: 'p3',
  slug: 'cola',
  name: 'Cola',
  type: CatalogProductType.variant,
  stock: 5,
);

const CatalogProductEntity _breakfast = CatalogProductEntity(
  id: 'p4',
  slug: 'breakfast-box',
  name: 'Breakfast box',
  type: CatalogProductType.bundle,
  priceFils: 2500,
  stock: 5,
);

/// The largest text the app lets through (`TextScalerClamp`).
const TextScaler _largestText = TextScaler.linear(1.3);

final Finder _marker = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is ShelfMarkerPainter,
);

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

  late Map<String, dynamic> enJson;
  late Map<String, dynamic> arJson;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    enJson = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    arJson = json.decode(
      await rootBundle.loadString('assets/i18n/ar.json'),
    ) as Map<String, dynamic>;
    Localization.load(const Locale('en'), translations: Translations(enJson));
  });

  void arabic() {
    Localization.load(const Locale('ar'), translations: Translations(arJson));
    addTearDown(
      () => Localization.load(
        const Locale('en'),
        translations: Translations(enJson),
      ),
    );
  }

  Widget card(CatalogProductEntity product, {int qty = 0}) =>
      CatalogProductCard(
        product: product,
        qty: qty,
        onTap: () {},
        onAdd: () {},
        onRemove: () {},
      );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection direction = TextDirection.ltr,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: textScaler, disableAnimations: reducedMotion),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Align(
                alignment: AlignmentDirectional.topStart,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void narrowestPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('is the shelf card: grey tile, no outline, no rating', (
    tester,
  ) async {
    await pump(tester, card(_lemon));

    final shelf = tester.widget<ShelfProductCard>(
      find.byType(ShelfProductCard),
    );
    expect(shelf.width, CatalogProductCard.defaultWidth);
    expect(shelf.reservesTagLine, isFalse, reason: 'a rail has one row');
    expect(find.byType(ShelfCardMedia), findsOneWidget);
    expect(find.byType(ShelfCardPrice), findsOneWidget);
    expect(find.byType(ShelfAddButton), findsOneWidget);

    final media = find.byType(ShelfCardMedia);
    // The whole picture square is the light-grey tile.
    final grey = find.descendant(
      of: media,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == AppColors.smallBackground,
      ),
    );
    expect(grey, findsWidgets);
    expect(
      tester.getSize(grey.first),
      const Size.square(CatalogProductCard.defaultWidth),
    );
    expect(find.descendant(of: media, matching: _outlined), findsNothing);
    // The old card's rating row and image badges are gone.
    expect(find.byType(RatingBadge), findsNothing);
    expect(find.text('4.8'), findsNothing);
    expect(find.byType(CatalogDiscountBadge), findsNothing);
    expect(find.byType(ShelfSaveBadge), findsNothing, reason: 'no deal');
  });

  testWidgets('a deal: lime marker under the price, struck price below it', (
    tester,
  ) async {
    await pump(tester, card(_deal));

    expect(find.text('Save 20%'), findsOneWidget);
    expect(_marker, findsOneWidget);
    final price = tester.getRect(find.text('1.000'));
    final was = tester.getRect(find.text('KD 1.250'));
    expect(was.top, greaterThanOrEqualTo(price.bottom), reason: 'own line');
    expect(
      tester.widget<Text>(find.text('KD 1.250')).style!.decoration,
      TextDecoration.lineThrough,
    );
    // The "Save" badge rides the picture's top-start corner.
    final tile = tester.getRect(find.byType(ShelfCardMedia));
    final badge = tester.getRect(find.byType(ShelfSaveBadge));
    expect(badge.left, tile.left + ShelfCardMedia.controlInset);
    expect(badge.top, tile.top + ShelfCardMedia.controlInset);
    // What a Pro member would pay, for everybody else.
    expect(find.text('pro'), findsOneWidget);
    expect(find.byType(CatalogDiscountBadge), findsNothing);
  });

  testWidgets('the unit line says "Multiple sizes" or "Bundle"', (
    tester,
  ) async {
    await pump(tester, card(_cola));
    expect(find.text('Multiple sizes'), findsOneWidget);
    expect(find.text('Choose options'), findsOneWidget, reason: 'no price');

    await pump(tester, card(_breakfast));
    expect(find.text('Bundle'), findsOneWidget);

    await pump(tester, card(_lemon));
    expect(find.text('Multiple sizes'), findsNothing);
    expect(find.text('Bundle'), findsNothing);
  });

  testWidgets('an untagged rail card reads name-first under its picture', (
    tester,
  ) async {
    await pump(tester, card(_lemon));
    expect(find.byType(ShelfTagPill), findsNothing);
    expect(
      tester.getTopLeft(find.text('Lemon')).dy,
      tester.getBottomLeft(find.byType(ShelfCardMedia)).dy + AppSpacing.s8,
    );

    await pump(tester, card(_deal));
    expect(find.byType(ShelfTagPill), findsOneWidget);
    expect(find.text('Best seller'), findsOneWidget);
  });

  testWidgets('its cell height is the shelf card\'s, scaled with the text', (
    tester,
  ) async {
    late double atRest;
    late double shelfAtRest;
    await pump(
      tester,
      Builder(
        builder: (context) {
          atRest = CatalogProductCard.cellHeight(context);
          shelfAtRest = ShelfProductCard.cellHeight(
            context,
            width: CatalogProductCard.defaultWidth,
          );
          return const SizedBox.shrink();
        },
      ),
    );
    expect(atRest, shelfAtRest);
    expect(
      atRest,
      CatalogProductCard.defaultWidth + CatalogProductCard.textBlockHeight,
    );
    expect(
      CatalogProductCard.textBlockHeight,
      ShelfProductCard.textBlockHeight,
    );

    late double scaled;
    late double shelfScaled;
    await pump(
      tester,
      Builder(
        builder: (context) {
          scaled = CatalogProductCard.cellHeight(context);
          shelfScaled = ShelfProductCard.cellHeight(
            context,
            width: CatalogProductCard.defaultWidth,
          );
          return const SizedBox.shrink();
        },
      ),
      textScaler: _largestText,
    );
    expect(scaled, shelfScaled);
    expect(scaled, greaterThan(atRest));
  });

  testWidgets('Arabic: the badge and the + swap corners, the marker too', (
    tester,
  ) async {
    arabic();
    await pump(tester, card(_deal), direction: TextDirection.rtl);

    expect(tester.takeException(), isNull);
    expect(find.text('وفّر 20٪'), findsOneWidget);
    expect(find.text('للعبوة'), findsOneWidget);
    final tile = tester.getRect(find.byType(ShelfCardMedia));
    final badge = tester.getRect(find.byType(ShelfSaveBadge));
    final add = tester.getRect(find.byType(ShelfAddButton));
    expect(badge.right, tile.right - ShelfCardMedia.controlInset);
    expect(add.left, tile.left + ShelfCardMedia.controlInset);
    expect(add.bottom, tile.bottom - ShelfCardMedia.controlInset);
    expect(
      (tester.widget<CustomPaint>(_marker).painter! as ShelfMarkerPainter)
          .textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('Arabic: the struck price keeps its label under the price\'s', (
    tester,
  ) async {
    arabic();
    Intl.defaultLocale = 'ar';
    addTearDown(() => Intl.defaultLocale = null);
    await pump(tester, card(_deal), direction: TextDirection.rtl);

    const label = 'د.ك';
    const struck = '$label 1.250';
    expect(find.text(struck), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(struck));

    /// The on-screen span of [part] of the struck line.
    (double, double) spanOf(String part) {
      final start = struck.indexOf(part);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + part.length),
      );
      final left = boxes.map((box) => box.left).reduce(math.min);
      final right = boxes.map((box) => box.right).reduce(math.max);
      return (
        paragraph.localToGlobal(Offset(left, 0)).dx,
        paragraph.localToGlobal(Offset(right, 0)).dx,
      );
    }

    final (labelLeft, labelRight) = spanOf(label);
    final (_, amountRight) = spanOf('1.250');
    // Read right to left like the price row: label first, then the amount.
    expect(amountRight, lessThanOrEqualTo(labelLeft));
    final priceLabel = tester.getRect(
      find.descendant(
        of: find.byType(ShelfCardPrice),
        matching: find.text(label),
      ),
    );
    expect(labelRight, closeTo(priceLabel.right, 0.5));
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      '320dp at the largest text, $direction: every card fits its rail cell',
      (tester) async {
        narrowestPhone(tester);
        if (direction == TextDirection.rtl) arabic();
        late double cell;
        await pump(
          tester,
          Builder(
            builder: (context) {
              cell = CatalogProductCard.cellHeight(context);
              return SizedBox(
                height: cell,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  // Lays out all five cards, not only the ones on screen.
                  scrollCacheExtent: const ScrollCacheExtent.pixels(
                    5 * (CatalogProductCard.defaultWidth + AppSpacing.s8),
                  ),
                  children: [
                    for (final (product, qty) in [
                      (_deal, 0),
                      (_deal, 3),
                      (_lemon, 0),
                      (_cola, 0),
                      (_breakfast, 1),
                    ]) ...[
                      // Free of the list's tight height, so the card lays
                      // out at its own height (an overflow still reports).
                      UnconstrainedBox(
                        alignment: AlignmentDirectional.topStart,
                        constrainedAxis: Axis.horizontal,
                        child: card(product, qty: qty),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                    ],
                  ],
                ),
              );
            },
          ),
          textScaler: _largestText,
          direction: direction,
        );
        await tester.pumpAndSettle();

        final error = tester.takeException();
        expect(
          error,
          isNull,
          reason: error is FlutterError ? error.toStringDeep() : '$error',
        );
        final heights = [
          for (final element
              in find.byType(ShelfProductCard, skipOffstage: false).evaluate())
            (element.renderObject! as RenderBox).size.height,
        ];
        expect(heights, hasLength(5));
        for (final height in heights) {
          expect(height, lessThanOrEqualTo(cell));
        }
        // The heights are the cards' own: the plain lemon (no tag, no deal,
        // no Pro price) comes out shorter than the cell.
        expect(heights[2], lessThan(cell));
      },
    );
  }

  testWidgets('under reduced motion the + turns into the stepper at once', (
    tester,
  ) async {
    await pump(tester, card(_lemon), reducedMotion: true);
    expect(find.byType(ShelfAddButton), findsOneWidget);

    await pump(tester, card(_lemon, qty: 2), reducedMotion: true);
    await tester.pump();
    expect(find.byType(ShelfAddButton), findsNothing);
    expect(find.byType(CatalogPillStepper), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the + speaks its action', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, card(_lemon));
    expect(find.bySemanticsLabel('Add to cart'), findsOneWidget);

    await pump(tester, card(_cola));
    expect(find.bySemanticsLabel('Choose options'), findsOneWidget);
    semantics.dispose();
  });
}
