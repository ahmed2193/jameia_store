import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_text_direction.dart';

void main() {
  bool? isRtl(String text) => AssistantTextDirection.isRtl(text);

  test('Arabic and English read their own way', () {
    expect(isRtl('أهلاً! إليك العروض'), isTrue);
    expect(isRtl('Here are the offers'), isFalse);
  });

  test('an Arabic sentence that starts with a Latin brand is still RTL', () {
    expect(isRtl('Almarai حليب كامل الدسم'), isTrue);
    expect(isRtl('Lurpak زبدة'), isTrue);
  });

  test('an English sentence with one Arabic word stays LTR', () {
    expect(isRtl('Try the مجبوس recipe tonight'), isFalse);
  });

  test('digits, punctuation and emoji alone have no direction', () {
    expect(isRtl(''), isNull);
    expect(isRtl('1.250 - 42% 🎉'), isNull);
    // …and do not count as words next to letters.
    expect(isRtl('2 × زبدة'), isTrue);
    expect(isRtl('2 × butter'), isFalse);
  });

  test('Arabic presentation forms count as Arabic', () {
    expect(isRtl('ﻻ'), isTrue);
  });
}
