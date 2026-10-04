// HeroBidiText: a text reads in its own direction (a Latin name in the
// Arabic app stays "2 Liter", an Arabic one in the English app keeps its
// order) while it sits on the layout's side.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/widgets/hero_bidi_text.dart';

Future<Text> _pump(
  WidgetTester tester,
  String text, {
  required TextDirection layout,
}) async {
  await tester.pumpWidget(
    Directionality(textDirection: layout, child: HeroBidiText(text)),
  );
  return tester.widget<Text>(find.byType(Text));
}

void main() {
  testWidgets('Latin in the Arabic app: left-to-right, on the right', (
    tester,
  ) async {
    final text = await _pump(tester, 'Milk 2 Liter', layout: TextDirection.rtl);

    expect(text.textDirection, TextDirection.ltr);
    expect(text.textAlign, TextAlign.right);
  });

  testWidgets('Arabic in the English app: right-to-left, on the left', (
    tester,
  ) async {
    final text = await _pump(tester, 'حليب ٢ لتر', layout: TextDirection.ltr);

    expect(text.textDirection, TextDirection.rtl);
    expect(text.textAlign, TextAlign.left);
  });

  testWidgets('no letters: the layout direction', (tester) async {
    final text = await _pump(
      tester,
      '10:00 - 12:00',
      layout: TextDirection.rtl,
    );

    expect(text.textDirection, TextDirection.rtl);
    expect(text.textAlign, TextAlign.right);
  });
}
