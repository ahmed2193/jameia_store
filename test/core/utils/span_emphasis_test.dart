// SpanEmphasis: one translated sentence with its amount or time in its own
// style; the plain text never changes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/utils/span_emphasis.dart';

const TextStyle _bold = TextStyle(fontWeight: FontWeight.w700);

void main() {
  test('splits around the part and styles only the part', () {
    final span = SpanEmphasis.around(
      'KD 0.200 saved with SAVE',
      'KD 0.200',
      emphasis: _bold,
    );
    final children = span.children!.cast<TextSpan>();
    expect(children, hasLength(2));
    expect(children.first.text, 'KD 0.200');
    expect(children.first.style, _bold);
    expect(children.last.text, ' saved with SAVE');
    expect(children.last.style, isNull);
    expect(span.toPlainText(), 'KD 0.200 saved with SAVE');
  });

  test('a part in the middle keeps both sides', () {
    final span = SpanEmphasis.around(
      'Arrives around 1:25 PM today',
      '1:25 PM',
      emphasis: _bold,
    );
    final texts = span.children!.cast<TextSpan>().map((s) => s.text);
    expect(texts, ['Arrives around ', '1:25 PM', ' today']);
    expect(span.toPlainText(), 'Arrives around 1:25 PM today');
  });

  test('a missing or empty part gives the plain sentence', () {
    for (final part in ['', 'KD 9.999']) {
      final span = SpanEmphasis.around(
        'Saving KD 0.200',
        part,
        emphasis: _bold,
      );
      expect(span.children, isNull);
      expect(span.text, 'Saving KD 0.200');
      expect(span.toPlainText(), 'Saving KD 0.200');
    }
  });

  testWidgets('find.text still matches the sentence', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text.rich(
          SpanEmphasis.around('Saving KD 0.200', 'KD 0.200', emphasis: _bold),
        ),
      ),
    );
    expect(find.text('Saving KD 0.200'), findsOneWidget);
  });
}
