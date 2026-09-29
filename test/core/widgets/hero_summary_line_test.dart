// A summary line keeps its value at the line's end edge (the price column of
// a bill), right in English and left in Arabic — never mid-line after the
// label's half — and a long value wraps inside its half.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/widgets/hero_summary_line.dart';

const double _width = 400;

Future<void> _pump(
  WidgetTester tester,
  TextDirection direction, {
  String value = 'KD 1.000',
}) => tester.pumpWidget(
  Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: _width,
        child: HeroSummaryLine(label: 'Subtotal', value: Text(value)),
      ),
    ),
  ),
);

void main() {
  testWidgets('the value sits at the end edge, left to right', (tester) async {
    await _pump(tester, TextDirection.ltr);

    final line = tester.getRect(find.byType(HeroSummaryLine));
    final value = tester.getRect(find.text('KD 1.000'));
    expect(value.right, moreOrLessEquals(line.right, epsilon: 0.5));
  });

  testWidgets('the value sits at the end edge, right to left', (tester) async {
    await _pump(tester, TextDirection.rtl);

    final line = tester.getRect(find.byType(HeroSummaryLine));
    final value = tester.getRect(find.text('KD 1.000'));
    expect(value.left, moreOrLessEquals(line.left, epsilon: 0.5));
  });

  testWidgets('a long value wraps inside its half, still at the end', (
    tester,
  ) async {
    await _pump(
      tester,
      TextDirection.ltr,
      value: 'A very long value that cannot fit on one line of its half',
    );

    final line = tester.getRect(find.byType(HeroSummaryLine));
    final value = tester.getRect(find.textContaining('A very long value'));
    expect(value.right, moreOrLessEquals(line.right, epsilon: 0.5));
    expect(value.width, lessThanOrEqualTo(_width / 2));
    expect(tester.takeException(), isNull);
  });
}
