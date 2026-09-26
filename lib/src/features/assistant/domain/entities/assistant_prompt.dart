import 'package:equatable/equatable.dart';

/// Where a draft stands against the `POST /v1/assistant/messages` limits.
enum AssistantPromptStatus { empty, valid, tooLong }

/// A message the customer may send: trimmed, 1..[maxLength] characters.
///
/// Lengths count Unicode code points (`runes`), like the backend's AJV
/// `maxLength`, so an emoji-heavy draft is judged exactly as the server
/// judges it (`String.length` would count an emoji twice).
class AssistantPrompt extends Equatable {
  const AssistantPrompt._(this.text);

  /// Backend body limit for `message`.
  static const int maxLength = 2000;

  /// The composer shows its character counter from this length on.
  static const int counterFrom = 1800;

  /// The trimmed text that goes on the wire.
  final String text;

  static AssistantPromptStatus statusOf(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return AssistantPromptStatus.empty;
    if (lengthOf(trimmed) > maxLength) return AssistantPromptStatus.tooLong;
    return AssistantPromptStatus.valid;
  }

  /// The sendable prompt, or `null` when [raw] is empty or too long.
  static AssistantPrompt? validate(String raw) =>
      statusOf(raw) == AssistantPromptStatus.valid
      ? AssistantPrompt._(raw.trim())
      : null;

  /// Whether the composer shows its `n / 2000` counter for [raw].
  static bool showsCounter(String raw) => lengthOf(raw.trim()) >= counterFrom;

  /// Characters as the backend counts them.
  static int lengthOf(String text) => text.runes.length;

  @override
  List<Object?> get props => [text];
}
