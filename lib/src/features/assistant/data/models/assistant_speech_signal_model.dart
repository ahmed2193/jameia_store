import 'package:equatable/equatable.dart';

/// The microphone permission, as the device reports it.
enum AssistantSpeechPermissionModel { granted, denied, blocked }

/// What the data layer does with a recognizer error.
enum AssistantSpeechErrorKind {
  /// Our own cancel echoed back: nothing happened.
  ignore,

  /// Nothing said or understood: listen again while the customer talks.
  noSpeech,

  /// The recognizer tripped (busy, restarting, a lost service): try again.
  retry,

  /// Offline, or the recognizer's server failed.
  network,

  /// The language is not installed or not supported.
  language,

  /// The microphone / speech permission is gone.
  permission,

  /// Anything else.
  other,
}

/// One thing the device's speech recognizer reported, in the order it came.
sealed class AssistantSpeechSignalModel extends Equatable {
  const AssistantSpeechSignalModel();

  @override
  List<Object?> get props => const [];
}

/// The microphone opened for a session (`listening`).
final class AssistantSpeechOpened extends AssistantSpeechSignalModel {
  const AssistantSpeechOpened();
}

/// The session's words so far; [isFinal] once the recognizer settled them.
final class AssistantSpeechWords extends AssistantSpeechSignalModel {
  const AssistantSpeechWords(this.text, {required this.isFinal});

  final String text;
  final bool isFinal;

  @override
  List<Object?> get props => [text, isFinal];
}

/// How loud the customer is: 0 (silence) to 1.
final class AssistantSpeechLoudness extends AssistantSpeechSignalModel {
  const AssistantSpeechLoudness(this.level);

  final double level;

  @override
  List<Object?> get props => [level];
}

/// The microphone closed (`notListening`); the last words may still come.
final class AssistantSpeechClosed extends AssistantSpeechSignalModel {
  const AssistantSpeechClosed();
}

/// The session is over (`done`).
final class AssistantSpeechEnded extends AssistantSpeechSignalModel {
  const AssistantSpeechEnded();
}

/// A recognizer error by its code (`speech_to_text`'s `errorMsg`: Android
/// `error_no_match`, `error_network`, …; iOS `error_retry`, …).
final class AssistantSpeechError extends AssistantSpeechSignalModel {
  const AssistantSpeechError(this.code);

  final String code;

  static const Set<String> _noSpeech = {
    'error_no_match',
    'error_speech_timeout',
  };
  static const Set<String> _retry = {
    'error_busy',
    'error_client',
    'error_retry',
    'error_listen_failed',
    'error_too_many_requests',
    'error_server_disconnected',
    'error_speech_recognizer_already_active',
    'error_speech_recognizer_connection_interrupted',
    'error_speech_recognizer_connection_invalidated',
  };
  static const Set<String> _network = {
    'error_network',
    'error_network_timeout',
    'error_server',
  };
  static const Set<String> _language = {
    'error_language_not_supported',
    'error_language_unavailable',
    'error_assets_not_installed',
  };
  static const Set<String> _permission = {
    'error_permission',
    'error_speech_recognizer_request_not_authorized',
  };
  static const String _cancelled = 'error_request_cancelled';

  AssistantSpeechErrorKind get kind => kindOf(code);

  /// Groups a recognizer error code; unknown codes are [other].
  static AssistantSpeechErrorKind kindOf(String code) {
    if (code == _cancelled) return AssistantSpeechErrorKind.ignore;
    if (_noSpeech.contains(code)) return AssistantSpeechErrorKind.noSpeech;
    if (_retry.contains(code)) return AssistantSpeechErrorKind.retry;
    if (_network.contains(code)) return AssistantSpeechErrorKind.network;
    if (_language.contains(code)) return AssistantSpeechErrorKind.language;
    if (_permission.contains(code)) return AssistantSpeechErrorKind.permission;
    return AssistantSpeechErrorKind.other;
  }

  @override
  List<Object?> get props => [code];
}
