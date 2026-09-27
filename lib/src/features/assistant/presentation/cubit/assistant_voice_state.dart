import 'package:equatable/equatable.dart';

import '../../domain/entities/assistant_voice_language.dart';
import '../../domain/entities/assistant_voice_problem.dart';
import '../../domain/entities/assistant_voice_waveform.dart';

/// Where a voice message stands.
enum AssistantVoicePhase {
  /// The mic waits for a press.
  idle,

  /// The finger is on the mic: recording (slide away cancels, up locks).
  holding,

  /// Recording hands-free: slid up, or started by a screen reader.
  locked,

  /// Let go: the last words are coming, then the message goes.
  sending,

  /// Stopped to read it over: the last words are coming, then the composer.
  stopping;

  bool get isRecording => this == holding || this == locked;

  bool get isFinishing => this == sending || this == stopping;
}

/// One-shot outcomes the composer reacts to once.
enum AssistantVoiceNotice {
  /// Send [AssistantVoiceState.noticeText].
  send,

  /// Put [AssistantVoiceState.noticeText] in the composer to read over.
  review,

  /// Slid away or binned: the bin animation.
  discarded,

  /// Only a tap: "hold to record, release to send".
  tooShort,

  /// Nothing was heard.
  noSpeech,

  /// The recognizer failed with [AssistantVoiceState.problem]; any words it
  /// heard are in [AssistantVoiceState.noticeText].
  failed,

  /// The microphone was refused this time.
  micDenied,

  /// The microphone is blocked: only the system settings can allow it.
  micBlocked,

  /// The device cannot turn speech into text: the mic goes away.
  unavailable,
}

/// The composer's voice message: its phase, the words heard, the timer and
/// the waveform — each read by its own small widget.
class AssistantVoiceState extends Equatable {
  const AssistantVoiceState({
    this.phase = AssistantVoicePhase.idle,
    this.transcript = '',
    this.elapsed = Duration.zero,
    this.waveform = AssistantVoiceWaveform.empty,
    this.available = true,
    this.language,
    this.notice,
    this.noticeText = '',
    this.problem,
    this.noticeSeq = 0,
  });

  final AssistantVoicePhase phase;

  /// Every word heard so far.
  final String transcript;

  /// The language the recording listens in (the last one's, between
  /// recordings); `null` before the first.
  final AssistantVoiceLanguage? language;

  /// Time since the mic was pressed.
  final Duration elapsed;

  final AssistantVoiceWaveform waveform;

  /// The device can take voice messages (the mic is offered).
  final bool available;

  /// Transient — cleared on every [copyWith].
  final AssistantVoiceNotice? notice;

  /// Transient words for [notice] (send / review / failed).
  final String noticeText;

  /// Transient, with [AssistantVoiceNotice.failed].
  final AssistantVoiceProblem? problem;

  /// Bumped with every notice, so the same notice twice still counts.
  final int noticeSeq;

  AssistantVoiceState copyWith({
    AssistantVoicePhase? phase,
    String? transcript,
    Duration? elapsed,
    AssistantVoiceWaveform? waveform,
    bool? available,
    AssistantVoiceLanguage? language,
  }) => AssistantVoiceState(
    phase: phase ?? this.phase,
    transcript: transcript ?? this.transcript,
    elapsed: elapsed ?? this.elapsed,
    waveform: waveform ?? this.waveform,
    available: available ?? this.available,
    language: language ?? this.language,
    noticeSeq: noticeSeq,
  );

  @override
  List<Object?> get props => [
    phase,
    transcript,
    elapsed,
    waveform,
    available,
    language,
    notice,
    noticeText,
    problem,
    noticeSeq,
  ];
}
