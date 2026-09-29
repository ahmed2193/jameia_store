// Finders for numbers drawn by the RollingNumber family: a rolling number is
// one Text per character, so `find.text('340')` no longer sees it. These
// match the whole text the widget shows instead.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/rolling_number.dart';
import 'package:hero_mart/src/core/motion/rolling_number_text.dart';

/// A [RollingNumber] or [RollingNumberText] currently showing [text]
/// ("11", "99+", "320 pts").
Finder findRolled(String text) => find.byWidgetPredicate(
  (widget) => switch (widget) {
    RollingNumber(:final value, :final format) => format(value) == text,
    RollingNumberText(:final value, :final format, text: final phrase) =>
      phrase(format(value)) == text,
    _ => false,
  },
  description: 'rolling number showing "$text"',
);
