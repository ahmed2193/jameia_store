import 'assistant_day_part.dart';

/// A question the welcome offers to start with: a short [labelKey] on the
/// chip, a full [promptKey] sent when tapped.
enum AssistantStarter {
  completeCart('assistant.starter_cart_label', 'assistant.starter_cart_prompt'),
  breakfast(
    'assistant.starter_breakfast_label',
    'assistant.starter_breakfast_prompt',
  ),
  dinner('assistant.starter_dinner_label', 'assistant.starter_dinner_prompt'),
  offers('assistant.starter_offers_label', 'assistant.starter_offers_prompt'),
  order('assistant.starter_order_label', 'assistant.starter_order_prompt'),
  delivery(
    'assistant.starter_delivery_label',
    'assistant.starter_delivery_prompt',
  );

  const AssistantStarter(this.labelKey, this.promptKey);

  final String labelKey;
  final String promptKey;

  /// How many starters the welcome shows.
  static const int shown = 4;

  /// The starters for this moment, most relevant first: finishing the cart
  /// when it has something in it, the meal of the time of day, then offers,
  /// orders and delivery.
  static List<AssistantStarter> pick({
    required AssistantDayPart dayPart,
    required bool hasCartItems,
  }) {
    final meal = switch (dayPart) {
      AssistantDayPart.morning => breakfast,
      AssistantDayPart.afternoon => null,
      AssistantDayPart.evening => dinner,
    };
    return <AssistantStarter>{
      if (hasCartItems) completeCart,
      ?meal,
      offers,
      order,
      delivery,
      breakfast,
    }.take(shown).toList(growable: false);
  }
}
