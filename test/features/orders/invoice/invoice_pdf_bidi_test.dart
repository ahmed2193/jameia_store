// The word-level bidi that sets mixed Arabic / Latin / number lines on the
// PDF: word order along the line, numbers and marks turned for a
// right-to-left read, brackets mirrored.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_pdf/invoice_pdf_bidi.dart';

/// The words as laid out, `|` between them, Arabic ones marked `*`.
String _laid(String text, {bool pageRtl = true}) {
  final line = InvoicePdfBidi.lineOf(text, pageRtl: pageRtl);
  final words = line.words.map((w) => w.arabic ? '*${w.text}' : w.text);
  return '${line.rtl ? 'rtl' : 'ltr'}: ${words.join('|')}';
}

void main() {
  test('what needs the word-by-word path', () {
    expect(InvoicePdfBidi.hasArabic('HM-1001'), isFalse);
    expect(InvoicePdfBidi.isMixed('الإجمالي (د.ك)'), isFalse);
    expect(InvoicePdfBidi.isMixed('صفحة 1 من 1'), isTrue);
    expect(InvoicePdfBidi.isMixed('خصم Pro'), isTrue);
  });

  test('brackets are mirrored for right-to-left text', () {
    expect(InvoicePdfBidi.mirrored('السعر (د.ك)'), 'السعر )د.ك(');
    expect(InvoicePdfBidi.mirrored('[a] «b»'), ']a[ »b«');
  });

  test('an Arabic line keeps its numbers in reading order', () {
    expect(_laid('صفحة 1 من 1'), 'rtl: *صفحة|1|*من|1');
    expect(_laid('21 سبتمبر 2026 10:42 ص'), 'rtl: 21|*سبتمبر|2026|10:42|*ص');
  });

  test("a number's trailing comma follows it right to left", () {
    expect(
      _laid('السالمية, قطعة 3, شارع 12'),
      'rtl: *السالمية,|*قطعة|,3|*شارع|12',
    );
  });

  test('a time window reads from its start, like the order page', () {
    expect(
      _laid('22 سبتمبر · 10:00 – 12:00'),
      'rtl: 22|*سبتمبر|·|10:00|–|12:00',
    );
  });

  test('a Latin run inside Arabic reads left to right', () {
    expect(_laid('خصم Pro'), 'rtl: *خصم|Pro');
    expect(
      _laid('حليب Almarai Milk 1L (كامل)'),
      'rtl: *حليب|1L|Milk|Almarai|*)كامل(',
    );
  });

  test('an Arabic run inside an English line reads right to left', () {
    expect(
      _laid('Replaced with حليب المراعي', pageRtl: false),
      'ltr: Replaced|with|*المراعي|*حليب',
    );
  });

  test('a line of marks and numbers takes the page direction', () {
    expect(InvoicePdfBidi.lineOf('12 – 14', pageRtl: false).rtl, isFalse);
    expect(InvoicePdfBidi.lineOf('12 – 14', pageRtl: true).rtl, isTrue);
  });
}
