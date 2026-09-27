/// The steps of the assistant's tour, in order: who it is, asking in your
/// own words, a cart it fills and you confirm, offers / orders / delivery,
/// and where to find it. Each carries the i18n keys of its title, its text
/// and what its little demo shows (for screen readers).
enum AssistantOnboardingStep {
  hello(
    'assistant.onboarding_hello_title',
    'assistant.onboarding_hello_body',
    'assistant.onboarding_hello_a11y',
  ),
  ask(
    'assistant.onboarding_ask_title',
    'assistant.onboarding_ask_body',
    'assistant.onboarding_ask_a11y',
  ),
  cart(
    'assistant.onboarding_cart_title',
    'assistant.onboarding_cart_body',
    'assistant.onboarding_cart_a11y',
  ),
  more(
    'assistant.onboarding_more_title',
    'assistant.onboarding_more_body',
    'assistant.onboarding_more_a11y',
  ),
  ready(
    'assistant.onboarding_ready_title',
    'assistant.onboarding_ready_body',
    'assistant.onboarding_ready_a11y',
  );

  const AssistantOnboardingStep(this.titleKey, this.bodyKey, this.sceneKey);

  final String titleKey;
  final String bodyKey;

  /// What the step's demo shows, said to screen readers.
  final String sceneKey;

  /// The first step greets the customer by name when there is one
  /// (`{name}`).
  String titleKeyFor({required bool withName}) => this == hello && withName
      ? 'assistant.onboarding_hello_title_name'
      : titleKey;

  bool get isLast => index == AssistantOnboardingStep.values.length - 1;
}
