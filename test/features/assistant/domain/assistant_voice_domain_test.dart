// Voice message rules and use cases: the waveform keeps the newest levels
// (clamped, silence for NaN), the policy tells a tap from a message and
// knows when a recording is full, the voice language falls back to English
// and switches between the two, and every use case is a straight call into
// the repository.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_prompt.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_access.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_event.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_language.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_policy.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_waveform.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/cancel_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/finish_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_voice_language_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/listen_to_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/open_assistant_voice_settings_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/prepare_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/request_assistant_voice_access_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/save_assistant_voice_language_usecase.dart';

import '../presentation/assistant_voice_fakes.dart';

void main() {
  group('waveform', () {
    test('keeps the newest levels, oldest first, up to its capacity', () {
      var waveform = AssistantVoiceWaveform.empty;
      expect(waveform.latest, 0);
      for (var i = 0; i < AssistantVoiceWaveform.capacity + 5; i++) {
        waveform = waveform.push(i / 100);
      }
      expect(waveform.levels, hasLength(AssistantVoiceWaveform.capacity));
      expect(waveform.levels.first, 0.05);
      expect(waveform.latest, (AssistantVoiceWaveform.capacity + 4) / 100);
    });

    test('clamps to 0..1; not-a-number is silence', () {
      final waveform = AssistantVoiceWaveform.empty
          .push(1.7)
          .push(-0.3)
          .push(double.nan);
      expect(waveform.levels, [1.0, 0.0, 0.0]);
    });

    test('compares by value and never changes in place', () {
      final one = AssistantVoiceWaveform.empty.push(0.4);
      final two = AssistantVoiceWaveform.empty.push(0.4);
      expect(one, two);
      expect(() => one.levels.add(0.1), throwsUnsupportedError);
    });
  });

  group('policy', () {
    const policy = AssistantVoicePolicy();

    test('a press under 350 ms is a tap, not a message', () {
      expect(policy.isAccidental(const Duration(milliseconds: 349)), isTrue);
      expect(policy.isAccidental(const Duration(milliseconds: 350)), isFalse);
    });

    test('full at the length cap, or when the words fill a message', () {
      expect(policy.isFull(const Duration(seconds: 89), 'milk'), isFalse);
      expect(policy.isFull(const Duration(seconds: 90), 'milk'), isTrue);
      expect(
        policy.isFull(Duration.zero, 'a' * AssistantPrompt.maxLength),
        isTrue,
      );
      expect(
        policy.isFull(Duration.zero, ' ${'a' * 1999} '),
        isFalse,
        reason: 'surrounding spaces do not count',
      );
    });
  });

  test('every use case is a straight call into the repository', () async {
    final repository = FakeVoiceRepository()
      ..prepared = AssistantVoiceAccess.granted
      ..access = const Right(AssistantVoiceAccess.blocked);

    expect(
      await PrepareAssistantVoiceUseCase(repository)(const NoParams()),
      const Right<Object, AssistantVoiceAccess?>(AssistantVoiceAccess.granted),
    );
    expect(
      await RequestAssistantVoiceAccessUseCase(repository)(const NoParams()),
      const Right<Object, AssistantVoiceAccess>(AssistantVoiceAccess.blocked),
    );

    final events = <AssistantVoiceEvent>[];
    ListenToAssistantVoiceUseCase(repository)(
      const ListenToAssistantVoiceParams(languageCode: 'ar'),
    ).listen(events.add);
    repository.take.add(const AssistantVoiceHeard('حليب'));
    await Future<void>.delayed(Duration.zero);
    expect(repository.languages, ['ar']);
    expect(events, const [AssistantVoiceHeard('حليب')]);

    await FinishAssistantVoiceUseCase(repository)(const NoParams());
    await CancelAssistantVoiceUseCase(repository)(const NoParams());
    await OpenAssistantVoiceSettingsUseCase(repository)(const NoParams());
    expect(repository.finishes, 1);
    expect(repository.cancels, 1);
    expect(repository.settingsOpened, 1);
    expect(
      const ListenToAssistantVoiceParams(languageCode: 'en'),
      const ListenToAssistantVoiceParams(languageCode: 'en'),
    );

    expect(
      await GetAssistantVoiceLanguageUseCase(repository)(const NoParams()),
      const Right<Object, AssistantVoiceLanguage?>(null),
    );
    await SaveAssistantVoiceLanguageUseCase(repository)(
      const SaveAssistantVoiceLanguageParams(AssistantVoiceLanguage.arabic),
    );
    expect(repository.savedLanguages, [AssistantVoiceLanguage.arabic]);
    expect(
      await GetAssistantVoiceLanguageUseCase(repository)(const NoParams()),
      const Right<Object, AssistantVoiceLanguage?>(
        AssistantVoiceLanguage.arabic,
      ),
    );
    expect(
      const SaveAssistantVoiceLanguageParams(AssistantVoiceLanguage.english),
      const SaveAssistantVoiceLanguageParams(AssistantVoiceLanguage.english),
    );
  });

  group('voice language', () {
    test('the app\'s language when the voice knows it; English otherwise', () {
      expect(AssistantVoiceLanguage.of('ar'), AssistantVoiceLanguage.arabic);
      expect(AssistantVoiceLanguage.of('AR'), AssistantVoiceLanguage.arabic);
      expect(AssistantVoiceLanguage.of('en'), AssistantVoiceLanguage.english);
      expect(AssistantVoiceLanguage.of('fr'), AssistantVoiceLanguage.english);
    });

    test('a stored code this app does not know is no language', () {
      expect(
        AssistantVoiceLanguage.tryParse('en'),
        AssistantVoiceLanguage.english,
      );
      expect(AssistantVoiceLanguage.tryParse('ar-KW'), isNull);
      expect(AssistantVoiceLanguage.tryParse(''), isNull);
    });

    test('the switch goes to the other one and back', () {
      expect(
        AssistantVoiceLanguage.arabic.other,
        AssistantVoiceLanguage.english,
      );
      expect(
        AssistantVoiceLanguage.english.other,
        AssistantVoiceLanguage.arabic,
      );
      expect(AssistantVoiceLanguage.arabic.code, 'ar');
    });
  });
}
