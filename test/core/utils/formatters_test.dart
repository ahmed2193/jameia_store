import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/core/utils/formatters.dart';

void main() {
  // DateFormat reads per-locale symbol tables; the app loads them through
  // EasyLocalization, a plain test has to ask for them.
  setUpAll(() => initializeDateFormatting());

  group('Formatters.isolate', () {
    test('wraps text in the first-strong isolate pair', () {
      final isolated = Formatters.isolate('+96550001110');

      expect(isolated.codeUnitAt(0), 0x2068);
      expect(isolated.codeUnitAt(isolated.length - 1), 0x2069);
      expect(isolated.substring(1, isolated.length - 1), '+96550001110');
    });

    test('empty text stays empty instead of becoming two markers', () {
      expect(Formatters.isolate(''), '');
    });
  });

  group('Formatters.date', () {
    test('writes the day in the asked language, not the wire format', () {
      final text = Formatters.date('en', DateTime(2026, 9, 22, 13));

      expect(text, isNot(contains('2026-09-22')));
      expect(text, contains('2026'));
    });

    test('no date is empty text', () {
      expect(Formatters.date('en', null), '');
    });
  });
}
