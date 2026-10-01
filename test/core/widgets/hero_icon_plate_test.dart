// HeroIconPlate: a white glyph on a rounded tile in the icon's fill family,
// every tile dark enough for white at 3:1 or more.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/design/hero_icon_fill_colors.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/widgets/hero_icon_plate.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: child),
);

/// WCAG 2 relative luminance of an sRGB colour.
double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrastWithWhite(Color color) => 1.05 / (_luminance(color) + 0.05);

BoxDecoration _tile(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
        as BoxDecoration;

void main() {
  testWidgets('a white glyph centred on the fill family tile', (tester) async {
    await tester.pumpWidget(_host(const HeroIconPlate(HeroIcons.bag)));
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons, hasLength(1), reason: 'no accent layer on a plate');
    expect(icons.single.icon, HeroIcons.bag);
    expect(icons.single.color, AppColors.white);
    expect(icons.single.size, closeTo(40 * 0.6, 0.001));
    final tile = _tile(tester);
    expect(tile.color, AppColors.primaryDark);
    expect(tile.borderRadius, BorderRadius.circular(40 * 0.28));
    expect(tester.getSize(find.byType(HeroIconPlate)), const Size(40, 40));
  });

  testWidgets('each fill picks its plate colour', (tester) async {
    for (final (icon, fill) in [
      (HeroIcons.star, HeroIconFill.amber),
      (HeroIcons.heart, HeroIconFill.red),
      (HeroIcons.chat, HeroIconFill.mint),
      (HeroIcons.mail, HeroIconFill.sky),
      (HeroIcons.sparkle, HeroIconFill.violet),
      (HeroIcons.egg, HeroIconFill.cream),
    ]) {
      await tester.pumpWidget(_host(HeroIconPlate(icon, size: 56)));
      expect(_tile(tester).color, fill.plate, reason: '$fill');
    }
  });

  testWidgets('amber sits on the dark slate of offer_voucher.svg', (
    tester,
  ) async {
    expect(HeroIconFill.amber.plate, AppColors.offlineSurface);
    await tester.pumpWidget(_host(const HeroIconPlate(HeroIcons.star)));
    expect(_tile(tester).color, AppColors.offlineSurface);
  });

  testWidgets('the crown takes the Pro indigo plate of pro_crown.svg', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const HeroIconPlate(HeroIcons.crown)));
    expect(_tile(tester).color, AppColors.proIndigo);
  });

  testWidgets('an icon without a fill sits on brand green', (tester) async {
    await tester.pumpWidget(_host(const HeroIconPlate(HeroIcons.chevronEnd)));
    expect(_tile(tester).color, AppColors.primaryDark);
  });

  testWidgets('an explicit colour wins', (tester) async {
    await tester.pumpWidget(
      _host(const HeroIconPlate(HeroIcons.crown, color: AppColors.proIndigo)),
    );
    expect(_tile(tester).color, AppColors.proIndigo);
  });

  testWidgets('the semantic label is read out once', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const HeroIconPlate(HeroIcons.gift, semanticLabel: 'Gift')),
    );
    expect(find.bySemanticsLabel('Gift'), findsOneWidget);
    semantics.dispose();
  });

  test('white reaches 3:1 on every plate colour', () {
    final plates = {
      for (final fill in HeroIconFill.values) fill.name: fill.plate,
      'fallback': HeroIconPlate.plateColorOf(HeroIcons.close),
      'crown': HeroIconPlate.plateColorOf(HeroIcons.crown),
    };
    for (final MapEntry(key: name, value: plate) in plates.entries) {
      final ratio = _contrastWithWhite(plate);
      expect(ratio, greaterThanOrEqualTo(3), reason: '$name $plate $ratio');
      // The hand formula agrees with Flutter's own luminance.
      expect(_luminance(plate), closeTo(plate.computeLuminance(), 0.001));
    }
  });
}
