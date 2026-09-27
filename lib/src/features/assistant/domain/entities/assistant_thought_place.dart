import 'assistant_thought_topic.dart';

/// Where the customer is while the buddy thinks out loud, and the topics
/// that fit there best: browsing favours offers, finding, the home and the
/// meal of the moment;
/// searching favours finding, choosing and questions; the account favours
/// help with a problem.
enum AssistantThoughtPlace {
  browsing({
    AssistantThoughtTopic.deals,
    AssistantThoughtTopic.find,
    AssistantThoughtTopic.home,
    AssistantThoughtTopic.meals,
    AssistantThoughtTopic.choose,
  }),
  searching({
    AssistantThoughtTopic.find,
    AssistantThoughtTopic.choose,
    AssistantThoughtTopic.ask,
  }),
  account({
    AssistantThoughtTopic.fix,
    AssistantThoughtTopic.ask,
    AssistantThoughtTopic.company,
  }),
  elsewhere({});

  const AssistantThoughtPlace(this.favoured);

  final Set<AssistantThoughtTopic> favoured;
}
