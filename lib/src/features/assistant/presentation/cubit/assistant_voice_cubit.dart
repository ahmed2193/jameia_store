import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/assistant_voice_access.dart';
import '../../domain/entities/assistant_voice_event.dart';
import '../../domain/entities/assistant_voice_language.dart';
import '../../domain/entities/assistant_voice_policy.dart';
import '../../domain/entities/assistant_voice_problem.dart';
import '../../domain/usecases/cancel_assistant_voice_usecase.dart';
import '../../domain/usecases/finish_assistant_voice_usecase.dart';
import '../../domain/usecases/get_assistant_voice_language_usecase.dart';
import '../../domain/usecases/listen_to_assistant_voice_usecase.dart';
import '../../domain/usecases/open_assistant_voice_settings_usecase.dart';
import '../../domain/usecases/prepare_assistant_voice_usecase.dart';
import '../../domain/usecases/request_assistant_voice_access_usecase.dart';
import '../../domain/usecases/save_assistant_voice_language_usecase.dart';
import 'assistant_voice_state.dart';

/// The composer's voice messages, WhatsApp style: press and hold the mic
/// to talk and let go to send; slide away to cancel; slide up to lock and
/// talk hands-free, then send, bin, or stop to read it over. The device
/// turns the speech into words, and the words are what the chat sends.
///
/// The recording clock ticks every [tick]: it moves the timer and adds one
/// waveform bar (the loudest level heard since the last one), so the
/// screen redraws about 14 times a second whatever the microphone reports.
/// Every recording is a new take; an answer that comes back for an earlier
/// one (a slow permission dialog, words after a cancel) is dropped.
///
/// A recording listens in the language the customer chose (remembered), or
/// the app's until they choose: many read the app in English and speak
/// Arabic, and the language switch beside the live words fixes a wrong one
/// mid-recording.
class AssistantVoiceCubit extends Cubit<AssistantVoiceState>
    with SafeCubitMixin<AssistantVoiceState> {
  AssistantVoiceCubit({
    required this._prepare,
    required this._requestAccess,
    required this._listen,
    required this._finish,
    required this._cancel,
    required this._openSettings,
    required this._savedLanguage,
    required this._saveLanguage,
    this.policy = const AssistantVoicePolicy(),
    this.tick = defaultTick,
  }) : super(const AssistantVoiceState());

  static const Duration defaultTick = Duration(milliseconds: 70);

  /// A bar with no new level fades to this share of the one before.
  static const double _fade = 0.6;

  final PrepareAssistantVoiceUseCase _prepare;
  final RequestAssistantVoiceAccessUseCase _requestAccess;
  final ListenToAssistantVoiceUseCase _listen;
  final FinishAssistantVoiceUseCase _finish;
  final CancelAssistantVoiceUseCase _cancel;
  final OpenAssistantVoiceSettingsUseCase _openSettings;
  final GetAssistantVoiceLanguageUseCase _savedLanguage;
  final SaveAssistantVoiceLanguageUseCase _saveLanguage;
  final AssistantVoicePolicy policy;
  final Duration tick;

  StreamSubscription<AssistantVoiceEvent>? _events;
  Timer? _clock;
  int _take = 0;
  bool _granted = false;
  double? _peak;
  double _bar = 0;

  /// The language the customer chose to talk in; `null` until they do.
  AssistantVoiceLanguage? _chosen;

  /// Readies the microphone when it is already allowed, so the first press
  /// starts at once; a device that cannot take voice hides the mic. Also
  /// reads the language the customer last chose.
  Future<void> prepare() async {
    final saved = await _savedLanguage(const NoParams());
    _chosen ??= saved.fold((_) => null, (language) => language);
    final result = await _prepare(const NoParams());
    final access = result.fold((_) => null, (access) => access);
    if (access == AssistantVoiceAccess.granted) _granted = true;
    if (access == AssistantVoiceAccess.unavailable &&
        state.phase == AssistantVoicePhase.idle) {
      safeEmit(state.copyWith(available: false));
    }
  }

  /// The finger went down on the mic.
  Future<void> hold(String languageCode) =>
      _start(languageCode, AssistantVoicePhase.holding);

  /// A screen reader's double tap: hands-free from the start.
  Future<void> startHandsFree(String languageCode) =>
      _start(languageCode, AssistantVoicePhase.locked);

  /// The finger came up while holding: send — or, after a mere tap, the
  /// "hold to record" hint.
  void release() {
    if (state.phase != AssistantVoicePhase.holding) return;
    if (policy.isAccidental(state.elapsed)) {
      _end(AssistantVoiceNotice.tooShort, cancel: true);
    } else {
      _stop(AssistantVoicePhase.sending);
    }
  }

  /// Slid up far enough: keep recording without the finger.
  void lock() {
    if (state.phase != AssistantVoicePhase.holding) return;
    safeEmit(state.copyWith(phase: AssistantVoicePhase.locked));
  }

  /// Slid away, or the bin: the words are dropped.
  void discard() {
    if (!state.phase.isRecording) return;
    _end(AssistantVoiceNotice.discarded, cancel: true);
  }

  /// The send button of a hands-free recording.
  void send() {
    if (state.phase == AssistantVoicePhase.locked) {
      _stop(AssistantVoicePhase.sending);
    }
  }

  /// Stop, and read the words over in the composer before sending.
  void review() {
    if (state.phase.isRecording) _stop(AssistantVoicePhase.stopping);
  }

  /// The app went to the background or the touch was taken away (a call, a
  /// system dialog): the words heard wait in the composer; an empty take is
  /// dropped quietly.
  void interrupt() {
    if (!state.phase.isRecording) return;
    if (_events == null || state.transcript.trim().isEmpty) {
      _end(null, cancel: true);
    } else {
      _stop(AssistantVoicePhase.stopping);
    }
  }

  Future<void> openSettings() => _openSettings(const NoParams());

  /// The language switch: listen in the other language — for this message
  /// and the next ones. The words heard so far were in the wrong one, so
  /// they go; the recording itself goes on.
  void switchLanguage() {
    final current = state.language;
    if (!state.phase.isRecording || current == null) return;
    final next = current.other;
    _chosen = next;
    unawaited(_saveLanguage(SaveAssistantVoiceLanguageParams(next)));
    safeEmit(state.copyWith(language: next, transcript: ''));
    // Still asking for the microphone: it opens in [next] once allowed.
    if (_events == null) return;
    final take = ++_take;
    unawaited(_events?.cancel());
    _events = null;
    _peak = null;
    _listenIn(take);
  }

  Future<void> _start(String languageCode, AssistantVoicePhase phase) async {
    if (state.phase != AssistantVoicePhase.idle || !state.available) return;
    final take = ++_take;
    _peak = null;
    _bar = 0;
    safeEmit(
      AssistantVoiceState(
        phase: phase,
        language: _chosen ?? AssistantVoiceLanguage.of(languageCode),
        noticeSeq: state.noticeSeq,
      ),
    );
    _startClock();
    final AssistantVoiceAccess? access;
    if (_granted) {
      access = AssistantVoiceAccess.granted;
    } else {
      final result = await _requestAccess(const NoParams());
      access = result.fold((_) => null, (access) => access);
    }
    if (access == AssistantVoiceAccess.granted) _granted = true;
    if (take != _take || isClosed) return;
    switch (access) {
      case AssistantVoiceAccess.granted:
        _listenIn(take);
      case AssistantVoiceAccess.denied:
        _end(AssistantVoiceNotice.micDenied);
      case AssistantVoiceAccess.blocked:
        _end(AssistantVoiceNotice.micBlocked);
      case AssistantVoiceAccess.unavailable:
        _end(AssistantVoiceNotice.unavailable, available: false);
      case null:
        _end(AssistantVoiceNotice.failed, problem: AssistantVoiceProblem.other);
    }
  }

  /// Listens for take [take] in the recording's language.
  void _listenIn(int take) {
    final language = state.language ?? AssistantVoiceLanguage.english;
    final events = _listen(
      ListenToAssistantVoiceParams(languageCode: language.code),
    );
    _events = events.listen(
      (event) => _onEvent(take, event),
      onError: (Object _) => _onEvent(
        take,
        AssistantVoiceFailed(
          AssistantVoiceProblem.other,
          text: state.transcript,
        ),
      ),
      onDone: () {
        // Closed without its last event (dropped elsewhere): keep the
        // words heard.
        if (take == _take) {
          _onEvent(take, AssistantVoiceDone(state.transcript));
        }
      },
    );
  }

  void _onEvent(int take, AssistantVoiceEvent event) {
    if (take != _take) return;
    switch (event) {
      case AssistantVoiceHeard(:final text):
        safeEmit(state.copyWith(transcript: text));
        if (state.phase.isRecording && policy.isFull(state.elapsed, text)) {
          _stop(AssistantVoicePhase.stopping);
        }
      case AssistantVoiceLevel(:final level):
        _peak = max(_peak ?? 0, level);
      case AssistantVoiceDone(:final text):
        final words = text.trim();
        _end(switch (state.phase) {
          _ when words.isEmpty => AssistantVoiceNotice.noSpeech,
          AssistantVoicePhase.sending => AssistantVoiceNotice.send,
          _ => AssistantVoiceNotice.review,
        }, text: words);
      case AssistantVoiceFailed(:final problem, :final text):
        if (problem == AssistantVoiceProblem.permission) _granted = false;
        final words = text.trim();
        _end(
          problem == AssistantVoiceProblem.noSpeech && words.isEmpty
              ? AssistantVoiceNotice.noSpeech
              : AssistantVoiceNotice.failed,
          text: words,
          problem: problem,
        );
    }
  }

  /// Stops listening; the done event brings the last words.
  void _stop(AssistantVoicePhase phase) {
    _stopClock();
    if (_events == null) {
      // Still asking for the microphone — its dialog is on screen: nothing
      // was heard and nothing to say; once answered, the next press talks.
      _end(null, cancel: true);
      return;
    }
    final take = _take;
    safeEmit(state.copyWith(phase: phase));
    unawaited(
      _finish(const NoParams()).then(
        (result) => result.fold((_) {
          if (take != _take) return;
          _end(
            AssistantVoiceNotice.failed,
            text: state.transcript.trim(),
            problem: AssistantVoiceProblem.other,
          );
        }, (_) {}),
      ),
    );
  }

  /// Back to the mic, with a one-shot [notice]. [cancel] also stops the
  /// microphone and drops its words.
  void _end(
    AssistantVoiceNotice? notice, {
    String text = '',
    AssistantVoiceProblem? problem,
    bool? available,
    bool cancel = false,
  }) {
    _take++;
    _stopClock();
    unawaited(_events?.cancel());
    _events = null;
    if (cancel) unawaited(_cancel(const NoParams()));
    safeEmit(
      AssistantVoiceState(
        available: available ?? state.available,
        language: state.language,
        notice: notice,
        noticeText: text,
        problem: problem,
        noticeSeq: notice == null ? state.noticeSeq : state.noticeSeq + 1,
      ),
    );
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(tick, _onTick);
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  void _onTick(Timer timer) {
    final elapsed = tick * timer.tick;
    final bar = _peak ?? _bar * _fade;
    _peak = null;
    _bar = bar;
    safeEmit(
      state.copyWith(elapsed: elapsed, waveform: state.waveform.push(bar)),
    );
    if (state.phase.isRecording && policy.isFull(elapsed, state.transcript)) {
      _stop(AssistantVoicePhase.stopping);
    }
  }

  @override
  Future<void> close() async {
    if (isClosed) return;
    final active = state.phase != AssistantVoicePhase.idle;
    _take++;
    _stopClock();
    await _events?.cancel();
    _events = null;
    if (active) unawaited(_cancel(const NoParams()));
    return super.close();
  }
}
