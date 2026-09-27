// The speech recognizer adapter against the plugin's platform channel:
// listen, stop and cancel reach the platform in the order they were made,
// each after the one before has answered (iOS ignores a cancel that comes
// before the microphone is open, and would leave it open), and a language
// list that never comes (Android 13+ without on-device recognition) is
// given up on instead of holding every message.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/assistant/data/datasources/assistant_speech_recognizer.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
  late List<String> calls;
  late Completer<bool> listenAnswer;
  late Completer<List<Object?>> languagesAnswer;

  setUp(() {
    calls = [];
    listenAnswer = Completer<bool>();
    languagesAnswer = Completer<List<Object?>>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call.method);
          return switch (call.method) {
            'listen' => listenAnswer.future,
            'locales' => languagesAnswer.future,
            _ => Future<Object?>.value(true),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  SpeechToTextRecognizer recognizer() => SpeechToTextRecognizer(
    speech: SpeechToText.withMethodChannel(),
    languagesTimeout: const Duration(milliseconds: 50),
  );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('a cancel made while the microphone is still opening reaches the '
      'platform once it is open', () async {
    final speech = recognizer();
    final listening = speech.listen(localeId: 'en-US');
    final cancelled = speech.cancel();
    await settle();
    expect(calls, ['initialize', 'listen']);

    listenAnswer.complete(true);
    expect(await listening, isTrue);
    await cancelled;
    expect(calls, ['initialize', 'listen', 'cancel']);
  });

  test('a stop waits for the listen before it, and the next listen for '
      'the stop', () async {
    final speech = recognizer();
    final first = speech.listen(localeId: 'en-US');
    final stopped = speech.stop();
    final second = speech.listen(localeId: 'en-US');
    await settle();
    expect(calls, ['initialize', 'listen']);

    listenAnswer.complete(true);
    await first;
    await stopped;
    await second;
    expect(calls, ['initialize', 'listen', 'stop', 'listen']);
  });

  test('a language list that never comes is given up on once; a late one '
      'still counts for the next message', () async {
    final speech = recognizer();
    expect(await speech.localeIds(), isEmpty);
    expect(await speech.localeIds(), isEmpty);
    expect(calls.where((method) => method == 'locales'), hasLength(1));

    languagesAnswer.complete(['en-US:English', 'ar-KW:Arabic (Kuwait)']);
    await settle();
    expect(await speech.localeIds(), ['ar-KW', 'en-US']);
    expect(calls.where((method) => method == 'locales'), hasLength(1));
  });
}
