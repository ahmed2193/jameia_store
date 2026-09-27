/// Why a voice message stopped before its words could be taken.
enum AssistantVoiceProblem {
  /// Nothing was said, or nothing could be understood.
  noSpeech,

  /// The recognizer needs the internet and could not reach it.
  network,

  /// The recognizer does not know the app's language on this device.
  language,

  /// The microphone or the recognizer is taken by something else.
  busy,

  /// The microphone permission was taken away mid-way.
  permission,

  /// Anything else the device reported.
  other,
}
