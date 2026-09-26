import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_day_part.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_starter.dart';

void main() {
  group('AssistantDayPart.of', () {
    DateTime at(int hour) => DateTime(2026, 9, 24, hour);

    test('morning 05–11, afternoon 12–16, evening (and night) otherwise', () {
      expect(AssistantDayPart.of(at(5)), AssistantDayPart.morning);
      expect(AssistantDayPart.of(at(11)), AssistantDayPart.morning);
      expect(AssistantDayPart.of(at(12)), AssistantDayPart.afternoon);
      expect(AssistantDayPart.of(at(16)), AssistantDayPart.afternoon);
      expect(AssistantDayPart.of(at(17)), AssistantDayPart.evening);
      expect(AssistantDayPart.of(at(2)), AssistantDayPart.evening);
    });

    test('greeting keys, with and without the name', () {
      expect(
        AssistantDayPart.morning.greetingKey(withName: true),
        'assistant.greeting_morning_name',
      );
      expect(
        AssistantDayPart.evening.greetingKey(withName: false),
        'assistant.greeting_evening',
      );
    });
  });

  group('AssistantStarter.pick', () {
    test('a morning with an empty cart: breakfast first', () {
      expect(
        AssistantStarter.pick(
          dayPart: AssistantDayPart.morning,
          hasCartItems: false,
        ),
        [
          AssistantStarter.breakfast,
          AssistantStarter.offers,
          AssistantStarter.order,
          AssistantStarter.delivery,
        ],
      );
    });

    test('something in the cart: finishing it comes first', () {
      final starters = AssistantStarter.pick(
        dayPart: AssistantDayPart.evening,
        hasCartItems: true,
      );
      expect(starters, hasLength(AssistantStarter.shown));
      expect(starters.first, AssistantStarter.completeCart);
      expect(starters[1], AssistantStarter.dinner);
    });

    test('the afternoon has no meal: always four, never repeated', () {
      final starters = AssistantStarter.pick(
        dayPart: AssistantDayPart.afternoon,
        hasCartItems: false,
      );
      expect(starters, [
        AssistantStarter.offers,
        AssistantStarter.order,
        AssistantStarter.delivery,
        AssistantStarter.breakfast,
      ]);
      expect(starters.toSet(), hasLength(starters.length));
    });
  });
}
