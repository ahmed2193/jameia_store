import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/assistant_speech_signal_model.dart';

/// The device's speech recognizer and the microphone permission — the only
/// place that knows the plugins. One session at a time; everything it hears
/// arrives on [signals], in order, as plain models.
abstract class AssistantSpeechRecognizer {
  /// The microphone permission as it stands, asking nothing (`denied` while
  /// undecided).
  Future<AssistantSpeechPermissionModel> permission();

  /// Asks for the microphone (and speech recognition on iOS) while it is
  /// undecided; answers at once otherwise.
  Future<AssistantSpeechPermissionModel> requestPermission();

  /// Prepares the recognizer once; `false` when the device has none.
  Future<bool> initialize();

  /// The recognizer's languages (`ar-KW`, `en_US` …); empty when unknown.
  Future<List<String>> localeIds();

  /// Opens the microphone for one session in [localeId] (the device's
  /// language when `null`); `false` when it could not start.
  Future<bool> listen({String? localeId});

  /// Closes the microphone; the session's last words still arrive.
  Future<void> stop();

  /// Closes the microphone and drops the session's words.
  Future<void> cancel();

  /// Opens this app's page in the system settings.
  Future<bool> openSettings();

  /// The recognizer is Apple's (iOS, macOS): it knows one Arabic, Saudi.
  bool get isApple;

  /// The phone's own languages, most preferred first (`ar-KW`, `en-US` …).
  List<String> get deviceLocaleIds;

  Stream<AssistantSpeechSignalModel> get signals;
}

/// [AssistantSpeechRecognizer] on `speech_to_text` (Android's
/// `SpeechRecognizer`, iOS `SFSpeechRecognizer`) and `permission_handler`.
///
/// Listen, stop and cancel reach the platform in the order they were made,
/// each after the one before has answered: iOS runs every call on its own
/// thread and ignores a stop or cancel that comes before the microphone is
/// open — which would leave it open.
class SpeechToTextRecognizer implements AssistantSpeechRecognizer {
  SpeechToTextRecognizer({
    SpeechToText? speech,
    this.languagesTimeout = defaultLanguagesTimeout,
  }) : _speech = speech ?? SpeechToText();

  /// Android reports RMS dB, about -2 (quiet room) to 10 (loud voice).
  static const double androidQuiet = -2;
  static const double androidLoud = 10;

  /// iOS reports dBFS, about -50 (quiet room) to 0; a voice peaks near -10.
  static const double appleQuiet = -50;
  static const double appleLoud = -10;

  /// How long the plugin waits for the last words after [stop] before it
  /// settles the latest partial ones itself.
  static const Duration _finalTimeout = Duration(milliseconds: 1200);

  /// Android 13+ answers the language list only on a device with on-device
  /// recognition, and never on others: past this, the language is asked
  /// for by name.
  static const Duration defaultLanguagesTimeout = Duration(seconds: 1);

  /// A platform call that never answers holds up the next no longer.
  static const Duration _turnLimit = Duration(seconds: 2);

  static const String _logName = 'voice';

  final SpeechToText _speech;
  final Duration languagesTimeout;
  final StreamController<AssistantSpeechSignalModel> _signals =
      StreamController<AssistantSpeechSignalModel>.broadcast();
  bool _ready = false;
  Future<List<String>>? _languages;
  Future<void> _turn = Future<void>.value();

  @override
  Stream<AssistantSpeechSignalModel> get signals => _signals.stream;

  @override
  Future<AssistantSpeechPermissionModel> permission() =>
      _permissions((permission) => permission.status);

  @override
  Future<AssistantSpeechPermissionModel> requestPermission() =>
      _permissions((permission) => permission.request());

  /// The microphone, then (iOS) speech recognition: the first refusal wins.
  Future<AssistantSpeechPermissionModel> _permissions(
    Future<PermissionStatus> Function(Permission permission) read,
  ) async {
    try {
      final microphone = await read(Permission.microphone);
      if (!microphone.isGranted) return _permissionOf(microphone);
      if (_isApple(defaultTargetPlatform)) {
        final speech = await read(Permission.speech);
        if (!speech.isGranted) return _permissionOf(speech);
      }
      return AssistantSpeechPermissionModel.granted;
    } on PlatformException catch (error) {
      // A request already on screen (a double tap): not granted this time.
      log('Microphone permission failed', name: _logName, error: error);
      return AssistantSpeechPermissionModel.denied;
    } on MissingPluginException {
      // No permission plugin on this platform (tests, desktop).
      return AssistantSpeechPermissionModel.denied;
    }
  }

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        finalTimeout: _finalTimeout,
      );
    } on PlatformException catch (error) {
      log('Speech recognizer unavailable', name: _logName, error: error);
      _ready = false;
    } on MissingPluginException {
      _ready = false;
    }
    return _ready;
  }

  /// Read once and shared; asked again only after a platform error.
  @override
  Future<List<String>> localeIds() => _languages ??= _readLanguages();

  Future<List<String>> _readLanguages() async {
    try {
      final request = _speech.locales();
      try {
        return _idsOf(await request.timeout(languagesTimeout));
      } on TimeoutException {
        log('Speech languages did not answer', name: _logName);
        // A late answer still replaces the guess, for the next message.
        unawaited(
          request.then<void>(
            (locales) => _languages = Future.value(_idsOf(locales)),
            onError: (Object _) {},
          ),
        );
        return const <String>[];
      }
    } on PlatformException catch (error) {
      log('Speech languages unknown', name: _logName, error: error);
      _languages = null;
      return const <String>[];
    } on MissingPluginException {
      _languages = null;
      return const <String>[];
    }
  }

  static List<String> _idsOf(List<LocaleName> locales) =>
      List<String>.unmodifiable([
        for (final locale in locales) locale.localeId,
      ]);

  @override
  Future<bool> listen({String? localeId}) => _inTurn(() async {
    if (!await initialize()) return false;
    // The plugin is one per app and keeps the listeners of whoever
    // initialized it first: make sure its reports come here.
    _speech
      ..statusListener = _onStatus
      ..errorListener = _onError;
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: _onLevel,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          localeId: localeId,
        ),
      );
      return true;
    } on ListenFailedException catch (error) {
      log('Listening failed: ${error.message}', name: _logName);
      return false;
    } on SpeechToTextNotInitializedException {
      _ready = false;
      return false;
    } on PlatformException catch (error) {
      log('Listening failed', name: _logName, error: error);
      return false;
    }
  });

  @override
  Future<void> stop() => _inTurn(() => _quietly(_speech.stop));

  @override
  Future<void> cancel() => _inTurn(() => _quietly(_speech.cancel));

  /// Runs [call] once every platform call made before it has answered — or
  /// has held the line for [_turnLimit] from its start.
  Future<T> _inTurn<T>(Future<T> Function() call) {
    final result = _turn.then((_) => call());
    final answered = result.then<void>((_) {}, onError: (Object _) {});
    _turn = _turn.then((_) => answered.timeout(_turnLimit, onTimeout: () {}));
    return result;
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  @override
  bool get isApple => _isApple(defaultTargetPlatform);

  @override
  List<String> get deviceLocaleIds => [
    for (final locale in PlatformDispatcher.instance.locales)
      locale.toLanguageTag(),
  ];

  /// Maps a platform's loudness reading to 0..1.
  @visibleForTesting
  static double normalizeLevel(double raw, TargetPlatform platform) {
    final (quiet, loud) = _isApple(platform)
        ? (appleQuiet, appleLoud)
        : (androidQuiet, androidLoud);
    if (raw.isNaN) return 0;
    return ((raw - quiet) / (loud - quiet)).clamp(0.0, 1.0).toDouble();
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (error) {
      log('Speech recognizer call failed', name: _logName, error: error);
    }
  }

  void _onResult(SpeechRecognitionResult result) => _signals.add(
    AssistantSpeechWords(result.recognizedWords, isFinal: result.finalResult),
  );

  void _onLevel(double level) => _signals.add(
    AssistantSpeechLoudness(normalizeLevel(level, defaultTargetPlatform)),
  );

  void _onStatus(String status) {
    final AssistantSpeechSignalModel? signal = switch (status) {
      SpeechToText.listeningStatus => const AssistantSpeechOpened(),
      SpeechToText.notListeningStatus => const AssistantSpeechClosed(),
      SpeechToText.doneStatus => const AssistantSpeechEnded(),
      _ => null,
    };
    if (signal != null) _signals.add(signal);
  }

  void _onError(SpeechRecognitionError error) =>
      _signals.add(AssistantSpeechError(error.errorMsg));

  static bool _isApple(TargetPlatform platform) =>
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  static AssistantSpeechPermissionModel _permissionOf(
    PermissionStatus status,
  ) => status.isPermanentlyDenied || status.isRestricted
      ? AssistantSpeechPermissionModel.blocked
      : AssistantSpeechPermissionModel.denied;
}
