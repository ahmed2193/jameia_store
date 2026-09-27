/// What a line the buddy thinks out loud is about — one of the ways the
/// assistant helps. Two lines in a row never share a topic.
enum AssistantThoughtTopic {
  /// Opening a visit ("How can I help you today?").
  greet,

  /// Finding products.
  find,

  /// Offers, discounts and prices.
  deals,

  /// Choosing, recommendations.
  choose,

  /// Any question.
  ask,

  /// Something went wrong.
  fix,

  /// Everything for the home and everyday life.
  home,

  /// The meal of the moment (breakfast, dinner).
  meals,

  /// Filling or finishing the cart.
  cart,

  /// Simply being there.
  company,
}
