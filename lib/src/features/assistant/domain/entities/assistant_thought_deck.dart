import 'dart:math';

import 'package:equatable/equatable.dart';

import 'assistant_day_part.dart';
import 'assistant_thought.dart';
import 'assistant_thought_place.dart';

/// The lines the buddy said lately, and what it says next — so it never
/// sounds like a loop: a line never follows one of the same topic, none of
/// the last [memory] lines comes back, lines of another part of the day
/// never come, and the moment tips the odds (the topics the
/// [AssistantThoughtPlace] favours, the meal of the moment, finishing a
/// cart that has items). Pure: the randomness is handed in, so it can be
/// seeded.
class AssistantThoughtDeck extends Equatable {
  const AssistantThoughtDeck([this.recent = const []]);

  /// How many lines it remembers.
  static const int memory = 6;

  static const int _plain = 1;
  static const int _favoured = 3;
  static const int _cart = 4;
  static const int _hello = 3;
  static const int _timely = 2;

  /// The lines said lately, oldest first.
  final List<AssistantThought> recent;

  /// The first line of a visit: the hello when meeting for the first time,
  /// otherwise one of the greetings of this [dayPart] — mostly the hello.
  AssistantThought opener(
    Random random, {
    required bool firstMeeting,
    required AssistantDayPart dayPart,
  }) {
    if (firstMeeting) return AssistantThought.hello;
    return _pick(random, {
      for (final thought in AssistantThought.values)
        if (thought.dealt && thought.opens && thought.fits(dayPart))
          thought: switch (thought) {
            AssistantThought.hello => _hello,
            _ when thought.dayPart != null => _timely,
            _ => _plain,
          },
    });
  }

  /// The line after the last one: another topic, none said lately (when
  /// every fresh one is out of place, a recent one may come back).
  AssistantThought next(
    Random random, {
    required AssistantThoughtPlace place,
    required bool hasCartItems,
    required AssistantDayPart dayPart,
  }) {
    Map<AssistantThought, int> odds({required bool fresh}) => _odds(
      place: place,
      hasCartItems: hasCartItems,
      dayPart: dayPart,
      fresh: fresh,
    );
    final fresh = odds(fresh: true);
    return _pick(random, fresh.isNotEmpty ? fresh : odds(fresh: false));
  }

  /// The deck once [thought] is said.
  AssistantThoughtDeck said(AssistantThought thought) {
    final lines = [...recent, thought];
    final forget = lines.length > memory ? lines.length - memory : 0;
    return AssistantThoughtDeck(List.unmodifiable(lines.skip(forget)));
  }

  Map<AssistantThought, int> _odds({
    required AssistantThoughtPlace place,
    required bool hasCartItems,
    required AssistantDayPart dayPart,
    required bool fresh,
  }) {
    final lastTopic = recent.isEmpty ? null : recent.last.topic;
    return {
      for (final thought in AssistantThought.values)
        if (thought.dealt &&
            !thought.opens &&
            thought.topic != lastTopic &&
            thought.fits(dayPart) &&
            (hasCartItems || !thought.needsCartItems) &&
            !(fresh && recent.contains(thought)))
          thought: _weight(thought, place),
    };
  }

  static int _weight(AssistantThought thought, AssistantThoughtPlace place) {
    if (thought.needsCartItems) return _cart;
    if (thought.dayPart != null) return _favoured;
    return place.favoured.contains(thought.topic) ? _favoured : _plain;
  }

  static AssistantThought _pick(
    Random random,
    Map<AssistantThought, int> odds,
  ) {
    var ticket = random.nextInt(odds.values.fold(0, (sum, w) => sum + w));
    for (final MapEntry(key: thought, value: weight) in odds.entries) {
      ticket -= weight;
      if (ticket < 0) return thought;
    }
    return odds.keys.last;
  }

  @override
  List<Object?> get props => [recent];
}
