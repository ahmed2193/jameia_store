// The buddy's lines: a visit opens with a greeting (the hello on a first
// meeting, a good morning / evening in their time); after it, lines never
// repeat a topic back to back nor a recent line, the place tips the odds
// towards what fits it, the meal of the moment and finishing the cart only
// come in their time, and every line has copy in both languages.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_day_part.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_starter.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_thought.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_thought_deck.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_thought_place.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_thought_topic.dart';

void main() {
  /// [count] lines in a row, each said before the next.
  List<AssistantThought> run(
    int count, {
    required Random random,
    AssistantThoughtPlace place = AssistantThoughtPlace.elsewhere,
    bool hasCartItems = false,
    AssistantDayPart dayPart = AssistantDayPart.afternoon,
  }) {
    var deck = const AssistantThoughtDeck();
    final said = <AssistantThought>[];
    for (var i = 0; i < count; i++) {
      final line = deck.next(
        random,
        place: place,
        hasCartItems: hasCartItems,
        dayPart: dayPart,
      );
      said.add(line);
      deck = deck.said(line);
    }
    return said;
  }

  List<AssistantThought> openers(AssistantDayPart dayPart, Random random) => [
    for (var i = 0; i < 400; i++)
      const AssistantThoughtDeck().opener(
        random,
        firstMeeting: false,
        dayPart: dayPart,
      ),
  ];

  test('a first meeting opens with the hello; later ones with a greeting, '
      'mostly the hello', () {
    expect(
      const AssistantThoughtDeck().opener(
        Random(1),
        firstMeeting: true,
        dayPart: AssistantDayPart.evening,
      ),
      AssistantThought.hello,
    );
    final said = openers(AssistantDayPart.afternoon, Random(1));
    expect(said.every((line) => line.opens), isTrue);
    final hellos = said.where((line) => line == AssistantThought.hello);
    expect(hellos.length, greaterThan(said.length / 2));
    expect(said.toSet(), hasLength(greaterThan(1)), reason: 'some variety');
  });

  test('good morning and good evening only in their time', () {
    final morning = openers(AssistantDayPart.morning, Random(2)).toSet();
    expect(morning, contains(AssistantThought.goodMorning));
    expect(morning, isNot(contains(AssistantThought.goodEvening)));
    final evening = openers(AssistantDayPart.evening, Random(2)).toSet();
    expect(evening, contains(AssistantThought.goodEvening));
    expect(evening, isNot(contains(AssistantThought.goodMorning)));
    final afternoon = openers(AssistantDayPart.afternoon, Random(2)).toSet();
    expect(afternoon.where((line) => line.dayPart != null), isEmpty);
  });

  test('never the same topic twice in a row, never a recent line again', () {
    final said = run(300, random: Random(2));
    for (var i = 1; i < said.length; i++) {
      expect(said[i].topic, isNot(said[i - 1].topic));
      final recent = said.sublist(max(0, i - AssistantThoughtDeck.memory), i);
      expect(recent, isNot(contains(said[i])), reason: 'line $i');
    }
  });

  test('after the opening, only dealt lines that are not greetings', () {
    final said = run(200, random: Random(3), hasCartItems: true);
    expect(said.any((line) => line.opens), isFalse);
    expect(said, isNot(contains(AssistantThought.coach)));
    expect(said, isNot(contains(AssistantThought.anythingElse)));
  });

  test('the meal of the moment: breakfast in the morning, dinner in the '
      'evening, neither in the afternoon', () {
    final morning = run(
      300,
      random: Random(6),
      dayPart: AssistantDayPart.morning,
    );
    expect(morning, contains(AssistantThought.breakfast));
    expect(morning, isNot(contains(AssistantThought.dinner)));
    final evening = run(
      300,
      random: Random(6),
      dayPart: AssistantDayPart.evening,
    );
    expect(evening, contains(AssistantThought.dinner));
    expect(evening, isNot(contains(AssistantThought.breakfast)));
    final afternoon = run(300, random: Random(6));
    expect(
      afternoon.where((line) => line.topic == AssistantThoughtTopic.meals),
      isEmpty,
    );
    expect(AssistantThought.breakfast.starter, AssistantStarter.breakfast);
    expect(AssistantThought.dinner.starter, AssistantStarter.dinner);
  });

  test('the place tips the odds towards what fits it', () {
    int fitting(AssistantThoughtPlace place) => run(
      600,
      random: Random(4),
      place: place,
    ).where((line) => place.favoured.contains(line.topic)).length;

    final elsewhere = run(600, random: Random(4));
    for (final place in [
      AssistantThoughtPlace.browsing,
      AssistantThoughtPlace.searching,
      AssistantThoughtPlace.account,
    ]) {
      final plain = elsewhere
          .where((line) => place.favoured.contains(line.topic))
          .length;
      expect(fitting(place), greaterThan(plain), reason: place.name);
    }
  });

  test('finishing the cart only while it has items — and then often', () {
    expect(
      run(300, random: Random(5)),
      isNot(contains(AssistantThought.finishCart)),
    );
    final withItems = run(300, random: Random(5), hasCartItems: true);
    expect(
      withItems.where((line) => line == AssistantThought.finishCart).length,
      greaterThan(withItems.length ~/ 20),
    );
    expect(AssistantThought.finishCart.starter, AssistantStarter.completeCart);
  });

  test('it remembers only the last lines', () {
    var deck = const AssistantThoughtDeck();
    for (final line in AssistantThought.values.take(10)) {
      deck = deck.said(line);
    }
    expect(deck.recent, hasLength(AssistantThoughtDeck.memory));
    expect(deck.recent.last, AssistantThought.values[9]);
  });

  test('every topic has lines, and the deals ask about offers', () {
    for (final topic in AssistantThoughtTopic.values) {
      expect(
        AssistantThought.values.where((line) => line.topic == topic),
        isNotEmpty,
        reason: topic.name,
      );
    }
    final deals = AssistantThought.values.where(
      (line) => line.topic == AssistantThoughtTopic.deals,
    );
    expect(
      deals.every((line) => line.starter == AssistantStarter.offers),
      isTrue,
    );
  });

  test('every line has copy in English and Arabic', () {
    Map<String, dynamic> read(String lang) =>
        (json.decode(File('assets/i18n/$lang.json').readAsStringSync())
                as Map<String, dynamic>)['assistant']
            as Map<String, dynamic>;
    final en = read('en');
    final ar = read('ar');
    for (final line in AssistantThought.values) {
      final key = line.textKey.split('.').last;
      expect(en[key], isA<String>(), reason: 'en $key');
      expect(ar[key], isA<String>(), reason: 'ar $key');
    }
  });
}
