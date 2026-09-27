import 'assistant_prompt.dart';

/// The rules of a voice message, the way WhatsApp taught everyone: press
/// and hold the mic to talk, let go to send, slide away to cancel, slide
/// up to keep talking hands-free.
///
/// The words are what gets sent — the device's speech recognizer turns
/// speech into text and `POST /v1/assistant/messages` takes text only. The
/// app keeps no recording; the recognizer may use its maker's online
/// service (Google, Apple), under the device's own privacy terms.
class AssistantVoicePolicy {
  const AssistantVoicePolicy({
    this.accidentalTap = defaultAccidentalTap,
    this.maxLength = defaultMaxLength,
  });

  /// A press shorter than this is a tap, not a message (WhatsApp: 350 ms);
  /// it shows "hold to record" instead.
  static const Duration defaultAccidentalTap = Duration(milliseconds: 350);

  /// A message stops by itself after this long and waits in the composer
  /// to be read over (about 1,500 characters: under the 2,000 limit).
  static const Duration defaultMaxLength = Duration(seconds: 90);

  final Duration accidentalTap;
  final Duration maxLength;

  /// Whether a press held for [held] was only a tap.
  bool isAccidental(Duration held) => held < accidentalTap;

  /// Whether a recording must stop: it ran [maxLength], or its words
  /// already fill a message.
  bool isFull(Duration elapsed, String transcript) =>
      elapsed >= maxLength ||
      AssistantPrompt.lengthOf(transcript.trim()) >= AssistantPrompt.maxLength;
}
