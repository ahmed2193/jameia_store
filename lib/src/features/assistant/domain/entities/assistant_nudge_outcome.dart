/// How the assistant's greeting ended — and the one engagement outside it,
/// the customer opening the chat from the floating launcher ([opened]).
enum AssistantNudgeOutcome {
  /// The customer tapped the greeting, a starter or the launcher.
  opened,

  /// Closed with the X or swiped away: "not now".
  dismissed,

  /// Left alone until it hid itself.
  ignored,
}
