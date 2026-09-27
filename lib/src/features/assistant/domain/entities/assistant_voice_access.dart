/// Whether the customer can talk to the assistant: the microphone
/// permission and a speech recognizer on the device.
enum AssistantVoiceAccess {
  /// The microphone is allowed and the device can turn speech into words.
  granted,

  /// The customer said no this time; asking again may still work.
  denied,

  /// Refused for good (or restricted by the device): only the system
  /// settings can change it.
  blocked,

  /// The device has no speech recognizer: the mic is not offered.
  unavailable,
}
