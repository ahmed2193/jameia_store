import 'assistant_day_part.dart';
import 'assistant_starter.dart';
import 'assistant_thought_topic.dart';

/// A short line the buddy thinks out loud above its launcher. Each shows one
/// way the assistant helps — finding products, offers, choosing, questions,
/// problems, the home, the meal of the moment — so the customer learns
/// what it does one friendly line at a time. A tap asks the chat the line's
/// [starter], if any. Some lines belong to a part of the day ([dayPart]).
/// [AssistantThoughtDeck] picks which line comes when.
enum AssistantThought {
  hello('assistant.buddy_thought_hello', AssistantThoughtTopic.greet),
  looking('assistant.buddy_thought_looking', AssistantThoughtTopic.greet),
  goodMorning(
    'assistant.buddy_thought_good_morning',
    AssistantThoughtTopic.greet,
    dayPart: AssistantDayPart.morning,
  ),
  goodEvening(
    'assistant.buddy_thought_good_evening',
    AssistantThoughtTopic.greet,
    dayPart: AssistantDayPart.evening,
  ),
  find('assistant.buddy_thought_find', AssistantThoughtTopic.find),
  findExactly('assistant.buddy_thought_find_exact', AssistantThoughtTopic.find),
  tell('assistant.buddy_thought_tell', AssistantThoughtTopic.find),
  deals(
    'assistant.buddy_thought_deals',
    AssistantThoughtTopic.deals,
    starter: AssistantStarter.offers,
  ),
  offers(
    'assistant.buddy_thought_offers',
    AssistantThoughtTopic.deals,
    starter: AssistantStarter.offers,
  ),
  price(
    'assistant.buddy_thought_price',
    AssistantThoughtTopic.deals,
    starter: AssistantStarter.offers,
  ),
  choose('assistant.buddy_thought_choose', AssistantThoughtTopic.choose),
  recommend('assistant.buddy_thought_recommend', AssistantThoughtTopic.choose),
  question('assistant.buddy_thought_question', AssistantThoughtTopic.ask),
  fix('assistant.buddy_thought_fix', AssistantThoughtTopic.fix),
  home('assistant.buddy_thought_home', AssistantThoughtTopic.home),
  breakfast(
    'assistant.buddy_thought_breakfast',
    AssistantThoughtTopic.meals,
    starter: AssistantStarter.breakfast,
    dayPart: AssistantDayPart.morning,
  ),
  dinner(
    'assistant.buddy_thought_dinner',
    AssistantThoughtTopic.meals,
    starter: AssistantStarter.dinner,
    dayPart: AssistantDayPart.evening,
  ),
  fillCart('assistant.buddy_thought_cart', AssistantThoughtTopic.cart),
  finishCart(
    'assistant.buddy_thought_cart_finish',
    AssistantThoughtTopic.cart,
    starter: AssistantStarter.completeCart,
    needsCartItems: true,
  ),
  together('assistant.buddy_thought_together', AssistantThoughtTopic.company),
  here('assistant.buddy_thought_here', AssistantThoughtTopic.company),

  /// Back from the chat. Never dealt.
  anythingElse(
    'assistant.buddy_thought_anything_else',
    AssistantThoughtTopic.company,
    dealt: false,
  ),

  /// Said once after the tour — where the launcher lives. Never dealt.
  coach('assistant.buddy_coach', AssistantThoughtTopic.company, dealt: false);

  const AssistantThought(
    this.textKey,
    this.topic, {
    this.starter,
    this.needsCartItems = false,
    this.dealt = true,
    this.dayPart,
  });

  /// i18n key of the line.
  final String textKey;
  final AssistantThoughtTopic topic;

  /// The question a tap on the line asks the chat, if any.
  final AssistantStarter? starter;

  /// Only while the cart has something in it.
  final bool needsCartItems;

  /// Comes from [AssistantThoughtDeck].
  final bool dealt;

  /// The only part of the day it is said in; `null` = any time.
  final AssistantDayPart? dayPart;

  /// Opens a visit, and only that.
  bool get opens => topic == AssistantThoughtTopic.greet;

  /// It may be said in [part] of the day.
  bool fits(AssistantDayPart part) => dayPart == null || dayPart == part;
}
