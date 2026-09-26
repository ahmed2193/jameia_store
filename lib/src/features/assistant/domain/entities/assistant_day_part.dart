/// Part of the customer's day, for the welcome's greeting and the meal it
/// suggests ("Good morning" + breakfast, "Good evening" + dinner).
enum AssistantDayPart {
  morning,
  afternoon,
  evening;

  static const int _morningFrom = 5;
  static const int _afternoonFrom = 12;
  static const int _eveningFrom = 17;

  /// The part of the day [at] falls in (local hours; night counts as
  /// evening).
  static AssistantDayPart of(DateTime at) {
    final hour = at.hour;
    if (hour >= _morningFrom && hour < _afternoonFrom) return morning;
    if (hour >= _afternoonFrom && hour < _eveningFrom) return afternoon;
    return evening;
  }

  /// i18n key of the greeting; the `_name` variant takes `{name}`.
  String greetingKey({required bool withName}) => switch (this) {
    morning when withName => 'assistant.greeting_morning_name',
    afternoon when withName => 'assistant.greeting_afternoon_name',
    evening when withName => 'assistant.greeting_evening_name',
    morning => 'assistant.greeting_morning',
    afternoon => 'assistant.greeting_afternoon',
    evening => 'assistant.greeting_evening',
  };
}
