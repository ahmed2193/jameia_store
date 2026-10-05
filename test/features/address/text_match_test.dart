// The bold of a search answer: where the typed words start words of its
// name, Google Maps style.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/address/domain/entities/text_match.dart';

void main() {
  test('a typed word in bold where it starts a word, whatever the case', () {
    expect(TextMatch.wordStartsIn('Salmiya', 'sal'), const [TextMatch(0, 3)]);
    expect(TextMatch.wordStartsIn('Sabah Al-Salem', 'SAL'), const [
      TextMatch(9, 12),
    ]);
    expect(TextMatch.wordStartsIn('Al Hamra Tower', 'hamra'), const [
      TextMatch(3, 8),
    ]);
  });

  test('never the inside of a word', () {
    expect(TextMatch.wordStartsIn('Salmiya', 'miya'), isEmpty);
    expect(TextMatch.wordStartsIn('Hawally', 'all'), isEmpty);
  });

  test('every typed word on its own', () {
    expect(TextMatch.wordStartsIn('Sabah Al-Salem', 'sabah al salem'), const [
      TextMatch(0, 5),
      TextMatch(6, 8),
      TextMatch(9, 14),
    ]);
    expect(TextMatch.wordStartsIn('Arabian Gulf St', 'gulf road'), const [
      TextMatch(8, 12),
    ]);
    expect(TextMatch.wordStartsIn('Salwa', '  '), isEmpty);
  });

  test('bold stretches: only those that fit, in order, overlaps and '
      'touching ones merged', () {
    expect(
      TextMatch.boldStretchesIn('Salmiya', const [
        TextMatch(4, 7),
        TextMatch(0, 3),
        TextMatch(2, 5),
        TextMatch(5, 99),
      ]),
      const [TextMatch(0, 7)],
    );
    expect(
      TextMatch.boldStretchesIn('Sabah Al-Salem', const [
        TextMatch(9, 12),
        TextMatch(0, 5),
      ]),
      const [TextMatch(0, 5), TextMatch(9, 12)],
    );
    expect(
      TextMatch.boldStretchesIn('Salwa', const [
        TextMatch(0, 2),
        TextMatch(2, 4),
      ]),
      const [TextMatch(0, 4)],
    );
  });

  test('a bold stretch takes the whole Arabic word it starts or ends in; a '
      'Latin one stays as matched', () {
    expect(
      TextMatch.boldStretchesIn('صباح السالم', const [TextMatch(7, 11)]),
      const [TextMatch(5, 11)],
    );
    expect(
      TextMatch.boldStretchesIn('صباح السالم', const [TextMatch(0, 2)]),
      const [TextMatch(0, 4)],
    );
    expect(
      TextMatch.boldStretchesIn('Salmiya', const [TextMatch(0, 3)]),
      const [TextMatch(0, 3)],
    );
  });

  test('an Arabic word may start after its article', () {
    expect(TextMatch.wordStartsIn('صباح السالم', 'سالم'), const [
      TextMatch(7, 11),
    ]);
    expect(TextMatch.wordStartsIn('صباح السالم', 'السالم'), const [
      TextMatch(5, 11),
    ]);
    // "الم" inside "السالم" starts no word.
    expect(TextMatch.wordStartsIn('صباح السالم', 'الم'), isEmpty);
  });
}
