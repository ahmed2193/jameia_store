import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/assistant_speech_signal_model.dart';
import '../models/assistant_voice_update_model.dart';
import 'assistant_speech_recognizer.dart';

/// Voice messages for the assistant, on the device's speech recognizer.
abstract class AssistantVoiceDataSource {
  /// Readies the recognizer when the microphone is already allowed, asking
  /// nothing; `null` while the customer has not been asked.
  Future<AssistantVoiceAccessModel?> prepare();

  /// The microphone permission, then the recognizer.
  Future<AssistantVoiceAccessModel> requestAccess();

  /// One message heard in [languageCode]: the words and levels as they
  /// come, then one done / failed update and the stream closes. A new
  /// message drops the one before; cancelling the subscription drops it too.
  Stream<AssistantVoiceUpdateModel> listen({required String languageCode});

  /// Stops listening; the words arrive as the done update.
  Future<void> finish();

  /// Stops listening and drops the words.
  Future<void> cancel();

  /// Opens this app's page in the system settings.
  Future<bool> openSettings();
}

/// For the customer a voice message is ONE take, however the device's
/// recognizer behaves: Android ends a session after a second or two of
/// silence (and after ~5 s with nothing said), so while the customer still
/// talks a new session opens and its words are appended. The take ends only
/// on [finish] / [cancel], or when the recognizer fails for good.
/// Hiccups (nothing heard, the recognizer busy) reopen the microphone
/// quietly — a busy one [maxReopens] times in a row at most.
///
/// Android may say a session is over before its last words arrive: the
/// take waits up to [lateWordsGrace] for them before it moves on, and up to
/// [finishGrace] after [finish], so nothing said is dropped.
///
/// A take that replaces a dropped one (the language switched mid-message)
/// opens the microphone [reopenDelay] after the recognizer let the old one
/// go: the old session's last reports (`notListening`, `done`) are still on
/// their way, and would read as the new session's end.
class AssistantVoiceDataSourceImpl implements AssistantVoiceDataSource {
  AssistantVoiceDataSourceImpl(
    this._recognizer, {
    this.reopenDelay = defaultReopenDelay,
    this.lateWordsGrace = defaultLateWordsGrace,
    this.finishGrace = defaultFinishGrace,
    this.openTimeout = defaultOpenTimeout,
  });

  /// A pause before the microphone reopens (sooner trips `error_busy`).
  static const Duration defaultReopenDelay = Duration(milliseconds: 200);
  static const Duration defaultLateWordsGrace = Duration(milliseconds: 700);

  /// Above the plugin's own 1.2 s wait for the last words after a stop.
  static const Duration defaultFinishGrace = Duration(milliseconds: 1500);

  /// The microphone reports open within this, or the session failed.
  static const Duration defaultOpenTimeout = Duration(seconds: 2);

  /// Failed starts in a row before the take gives up.
  static const int maxReopens = 3;

  /// Regions tried first for a language (Kuwait first), then any listed —
  /// all known to Google's recognizer, as the phone's own region must be
  /// to be asked for.
  static const Map<String, List<String>> _preferredRegions = {
    'ar': [
      'KW', 'SA', 'AE', 'QA', 'BH', 'OM', 'JO', 'EG', //
      'LB', 'IQ', 'PS', 'MA', 'DZ', 'TN', 'YE',
    ],
    'en': ['US', 'GB', 'AU', 'IN', 'CA', 'IE', 'NZ', 'ZA'],
  };

  /// Apple's recognizer knows ONE Arabic — Saudi — and will not start in
  /// any other, whatever its list and the phone's own region say.
  static const Map<String, String> _appleLocales = {
    'ar': 'ar-SA',
    'en': 'en-US',
  };

  /// A region subtag a recognizer takes: two letters (not `001`, not empty).
  static final RegExp _regionCode = RegExp(r'^[A-Z]{2}$');

  /// Asked for when the recognizer lists nothing in the language: its list
  /// may hold only the on-device languages, and the online one knows more.
  static const Map<String, String> _fallbackLocales = {
    'ar': 'ar-KW',
    'en': 'en-US',
  };

  final AssistantSpeechRecognizer _recognizer;
  final Duration reopenDelay;
  final Duration lateWordsGrace;
  final Duration finishGrace;
  final Duration openTimeout;

  _VoiceTake? _take;

  /// Done [reopenDelay] after the recognizer let the last dropped take go.
  Future<void> _letGo = Future<void>.value();

  @override
  Future<AssistantVoiceAccessModel?> prepare() async {
    switch (await _recognizer.permission()) {
      case AssistantSpeechPermissionModel.denied:
        return null;
      case AssistantSpeechPermissionModel.blocked:
        return AssistantVoiceAccessModel.blocked;
      case AssistantSpeechPermissionModel.granted:
        final access = await _ready();
        // The language list is read once; read it now, not on the press.
        if (access == AssistantVoiceAccessModel.granted) {
          await _recognizer.localeIds();
        }
        return access;
    }
  }

  @override
  Future<AssistantVoiceAccessModel> requestAccess() async {
    switch (await _recognizer.requestPermission()) {
      case AssistantSpeechPermissionModel.denied:
        return AssistantVoiceAccessModel.denied;
      case AssistantSpeechPermissionModel.blocked:
        return AssistantVoiceAccessModel.blocked;
      case AssistantSpeechPermissionModel.granted:
        return _ready();
    }
  }

  Future<AssistantVoiceAccessModel> _ready() async =>
      await _recognizer.initialize()
      ? AssistantVoiceAccessModel.granted
      : AssistantVoiceAccessModel.unavailable;

  @override
  Stream<AssistantVoiceUpdateModel> listen({required String languageCode}) {
    unawaited(_take?.drop());
    final take = _VoiceTake(this);
    _take = take;
    unawaited(take.begin(languageCode));
    return take.updates;
  }

  @override
  Future<void> finish() async => _take?.finish();

  @override
  Future<void> cancel() async => _take?.drop();

  @override
  Future<bool> openSettings() => _recognizer.openSettings();

  /// The recognizer language for [languageCode]. On Apple, the one it
  /// knows. Elsewhere the phone's own region for the language (the
  /// customer's dialect) when a known one; else a listed one, preferred
  /// regions first; else a sensible default. Only tags with a region: the
  /// plugin lists the phone's own language first, as `ar_` when it has no
  /// region — a tag no recognizer takes.
  @visibleForTesting
  static String? pickLocale(
    List<String> available,
    String languageCode, {
    bool apple = false,
    List<String> device = const [],
  }) {
    final language = languageCode.toLowerCase();
    if (apple) return _appleLocales[language];
    final known = _preferredRegions[language] ?? const <String>[];
    for (final id in device) {
      if (_languageOf(id) == language && known.contains(_regionOf(id))) {
        return id;
      }
    }
    final spoken = [
      for (final id in available)
        if (_languageOf(id) == language && _regionOf(id) != null) id,
    ];
    for (final region in known) {
      for (final id in spoken) {
        if (_regionOf(id) == region) return id;
      }
    }
    return spoken.isNotEmpty ? spoken.first : _fallbackLocales[language];
  }

  static List<String> _partsOf(String id) => id.replaceAll('_', '-').split('-');

  static String _languageOf(String id) => _partsOf(id).first.toLowerCase();

  static String? _regionOf(String id) {
    final parts = _partsOf(id);
    if (parts.length < 2) return null;
    final region = parts.last.toUpperCase();
    return _regionCode.hasMatch(region) ? region : null;
  }

  void _over(_VoiceTake take) {
    if (identical(_take, take)) _take = null;
  }

  /// The next take opens no sooner than [reopenDelay] after [cancelled].
  void _dropped(Future<void> cancelled) {
    _letGo = cancelled.then(
      (_) => Future<void>.delayed(reopenDelay),
      onError: (Object _) {},
    );
  }
}

enum _TakeMode { listening, finishing, over }

/// One voice message across the recognizer's sessions.
class _VoiceTake {
  _VoiceTake(this._source);

  final AssistantVoiceDataSourceImpl _source;
  late final StreamController<AssistantVoiceUpdateModel> _updates =
      StreamController<AssistantVoiceUpdateModel>(onCancel: drop);
  StreamSubscription<AssistantSpeechSignalModel>? _signals;
  _TakeMode _mode = _TakeMode.listening;
  String? _localeId;
  Timer? _timer;

  /// Words of the sessions already wrapped up.
  String _heard = '';

  /// [_heard] before the last session's words joined it (`null` in the
  /// first session): that session's late words replace its own.
  String? _heardBefore;

  /// Words of the running session, and whether the recognizer settled them.
  String _words = '';
  bool _settled = false;

  /// A session was opened and is not wrapped up yet.
  bool _inSession = false;

  /// The microphone reported open for the running session — and whether
  /// it ever did: words that come before are the last session's.
  bool _open = false;
  bool _opened = false;

  /// The running session is over or stopping: waiting for its last words.
  bool _awaitingWords = false;

  /// The running session's error, which decides what comes after it.
  AssistantSpeechErrorKind? _error;
  int _reopens = 0;
  String _lastHeard = '';

  AssistantSpeechRecognizer get _recognizer => _source._recognizer;

  Stream<AssistantVoiceUpdateModel> get updates => _updates.stream;

  String get _text => _join(_heard, _words);

  Future<void> begin(String languageCode) async {
    _signals = _recognizer.signals.listen(_onSignal);
    final ids = await _recognizer.localeIds();
    _localeId = AssistantVoiceDataSourceImpl.pickLocale(
      ids,
      languageCode,
      apple: _recognizer.isApple,
      device: _recognizer.deviceLocaleIds,
    );
    await _source._letGo;
    await _openSession();
  }

  Future<void> finish() async {
    if (_mode != _TakeMode.listening) return;
    _mode = _TakeMode.finishing;
    _cancelTimer();
    // Between sessions, or the microphone never opened: nothing to wait
    // for — unless the microphone closed with its last words still due.
    final wordsDue = _awaitingWords && _error == null;
    if (!_inSession || (!_open && _words.isEmpty && !wordsDue)) {
      _inSession = false;
      _end(_done());
      await _recognizer.cancel();
      return;
    }
    if (_settled && !_open) {
      _wrapUp();
      return;
    }
    _awaitingWords = true;
    _timer = Timer(_source.finishGrace, _wrapUp);
    await _recognizer.stop();
  }

  Future<void> drop() async {
    if (_mode == _TakeMode.over) return;
    _mode = _TakeMode.over;
    _cancelTimer();
    _inSession = false;
    _source._over(this);
    unawaited(_signals?.cancel());
    unawaited(_updates.close());
    final cancelled = _recognizer.cancel();
    _source._dropped(cancelled);
    await cancelled;
  }

  Future<void> _openSession() async {
    if (_mode != _TakeMode.listening) return;
    _words = '';
    _settled = false;
    _open = false;
    _opened = false;
    _awaitingWords = false;
    _error = null;
    _inSession = true;
    _cancelTimer();
    _timer = Timer(_source.openTimeout, _onOpenTimeout);
    final started = await _recognizer.listen(localeId: _localeId);
    if (!started && _inSession && !_open) {
      _error = AssistantSpeechErrorKind.retry;
      _wrapUp();
    }
  }

  void _onOpenTimeout() {
    if (!_inSession || _open) return;
    _error = AssistantSpeechErrorKind.retry;
    unawaited(_recognizer.cancel());
    _wrapUp();
  }

  void _onSignal(AssistantSpeechSignalModel signal) {
    if (_mode == _TakeMode.over || !_inSession) return;
    switch (signal) {
      case AssistantSpeechOpened():
        _open = true;
        _opened = true;
        if (!_awaitingWords) _cancelTimer();
      case AssistantSpeechWords(:final text, :final isFinal):
        _onWords(text.trim(), isFinal: isFinal);
      case AssistantSpeechLoudness(:final level):
        if (_mode == _TakeMode.listening && _open) {
          _emit(AssistantVoiceLevelModel(level));
        }
      // Before this session's microphone opened, an end is a dropped
      // session's (iOS reports a cancelled one late); a session that never
      // opens fails by its error or the open timeout.
      case AssistantSpeechClosed() when _opened:
        _open = false;
        _awaitLastWords();
      case AssistantSpeechEnded() when _opened:
        _open = false;
        _onSessionEnded();
      case AssistantSpeechClosed() || AssistantSpeechEnded():
        return;
      case AssistantSpeechError(:final kind):
        _onError(kind);
    }
  }

  void _onWords(String text, {required bool isFinal}) {
    if (!_opened) return _onLateWords(text);
    _words = text;
    _settled = isFinal;
    if (text.isNotEmpty) _reopens = 0;
    _publish();
    if (isFinal && _awaitingWords) _wrapUp();
  }

  /// Words before this session's microphone opened are the last session's,
  /// settled late (iOS finishes a session while the next one starts): they
  /// replace what it had said instead of saying it twice. In a take's first
  /// session they belong to an earlier take and are dropped.
  void _onLateWords(String text) {
    final before = _heardBefore;
    if (before == null || text.isEmpty) return;
    _heard = _join(before, text);
    _publish();
  }

  void _publish() {
    final heard = _text;
    if (heard == _lastHeard) return;
    _lastHeard = heard;
    _emit(AssistantVoiceHeardModel(heard));
  }

  /// The microphone closed; the session's end or last words should follow.
  /// If they don't, move on anyway ([finish] runs its own, longer wait).
  void _awaitLastWords() {
    if (_awaitingWords) return;
    _awaitingWords = true;
    _cancelTimer();
    _timer = Timer(_source.lateWordsGrace, _wrapUp);
  }

  /// The session is over. Its words are in when settled; after an error
  /// with nothing heard none will come. Otherwise wait for the last ones.
  void _onSessionEnded() {
    if (_settled || (_words.isEmpty && _error != null)) {
      _wrapUp();
    } else {
      _awaitLastWords();
    }
  }

  void _onError(AssistantSpeechErrorKind kind) {
    switch (kind) {
      case AssistantSpeechErrorKind.ignore:
        return;
      case AssistantSpeechErrorKind.noSpeech:
      case AssistantSpeechErrorKind.retry:
        // The session is over; its end follows, then the take goes on.
        _error = kind;
        _awaitLastWords();
      case AssistantSpeechErrorKind.network:
      case AssistantSpeechErrorKind.language:
      case AssistantSpeechErrorKind.permission:
      case AssistantSpeechErrorKind.other:
        _fail(kind);
    }
  }

  /// Folds the session's words into the take, then finishes it or opens
  /// the next session.
  void _wrapUp() {
    if (!_inSession || _mode == _TakeMode.over) return;
    _cancelTimer();
    _inSession = false;
    _open = false;
    _awaitingWords = false;
    _heardBefore = _heard;
    _heard = _join(_heard, _words);
    _words = '';
    _settled = false;
    final busy = _error == AssistantSpeechErrorKind.retry;
    _error = null;
    if (_mode == _TakeMode.finishing) return _end(_done());
    if (busy) {
      if (_reopens >= AssistantVoiceDataSourceImpl.maxReopens) {
        return _fail(AssistantSpeechErrorKind.retry);
      }
      _reopens++;
    }
    // A busy recognizer gets a little longer each time.
    _timer = Timer(_source.reopenDelay * (busy ? _reopens + 1 : 1), () {
      unawaited(_openSession());
    });
  }

  AssistantVoiceUpdateModel _done() => AssistantVoiceDoneModel(_text);

  void _fail(AssistantSpeechErrorKind kind) {
    final text = _text;
    unawaited(_recognizer.cancel());
    _end(AssistantVoiceFailedModel(kind, text: text));
  }

  void _end(AssistantVoiceUpdateModel last) {
    if (_mode == _TakeMode.over) return;
    _mode = _TakeMode.over;
    _cancelTimer();
    _inSession = false;
    _source._over(this);
    unawaited(_signals?.cancel());
    _updates.add(last);
    unawaited(_updates.close());
  }

  void _emit(AssistantVoiceUpdateModel update) {
    if (_mode != _TakeMode.over) _updates.add(update);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  static String _join(String before, String after) {
    if (before.isEmpty) return after;
    if (after.isEmpty) return before;
    return '$before $after';
  }
}
