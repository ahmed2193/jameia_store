// Formatters.clock / date / dateTime: the language's own pattern (Arabic
// keeps ص / م and its month names) with Western digits like every other
// number in the app; a clock is shown in local time.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:jameia_mart/src/core/utils/formatters.dart';

/// U+202F NARROW NO-BREAK SPACE, written by its code point.
final String _narrowSpace = String.fromCharCode(0x202F);

/// Arabic-Indic digits ٠–٩.
final RegExp _arabicIndic = RegExp('[٠-٩]');

void main() {
  // DateFormat reads per-locale symbol tables; the app loads them through
  // EasyLocalization, a plain test has to ask for them.
  setUpAll(() => initializeDateFormatting());

  group('Formatters.clock uses jm per language', () {
    final at = DateTime(2026, 9, 26, 17, 55);

    test('English reads 5:55 PM', () {
      // CLDR puts a narrow no-break space before the day period.
      expect(
        Formatters.clock('en', at).replaceAll(_narrowSpace, ' '),
        '5:55 PM',
      );
    });

    test('Arabic keeps ص/م with Latin digits', () {
      expect(
        Formatters.clock('ar', at),
        (DateFormat.jm('ar')..useNativeDigits = false).format(at),
      );
      expect(Formatters.clock('ar', at), isNot(Formatters.clock('en', at)));

      final morning = Formatters.clock('ar', DateTime(2026, 9, 26, 1, 25));
      expect(morning, contains('1:25'));
      expect(morning, contains('ص'));
      expect(morning, isNot(contains(_arabicIndic)));
      expect(Formatters.clock('ar', at), contains('م'));
    });

    test('a UTC instant is shown in local time', () {
      final utc = at.toUtc();
      expect(Formatters.clock('en', utc), Formatters.clock('en', at));
    });
  });

  group('Arabic dates keep their names with Latin digits', () {
    test('date', () {
      final text = Formatters.date('ar', DateTime(2026, 10, 31));
      expect(text, contains('31'));
      expect(text, contains('أكتوبر'));
      expect(text, contains('2026'));
      expect(text, isNot(contains(_arabicIndic)));
    });

    test('dateTime', () {
      final text = Formatters.dateTime('ar', DateTime(2026, 10, 31, 9, 5));
      expect(text, contains('31'));
      expect(text, contains('9:05'));
      expect(text, isNot(contains(_arabicIndic)));
    });
  });
}
