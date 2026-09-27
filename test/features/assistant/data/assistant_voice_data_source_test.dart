// A voice message over a scripted speech recognizer: access (asking only
// on a press), the recognizer language (Kuwait first), and the take — words
// stitched across the sessions Android ends on silence, the last words
// awaited after a stop (Android says "done" before them), hiccups reopening
// the microphone quietly, lasting failures keeping the words, and a cancel
// or a new message dropping everything. Also the error groups, the loudness
// scale, the mapper and the repository.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/storage/local_storage.dart';
import 'package:hero_mart/src/features/assistant/data/datasources/assistant_speech_recognizer.dart';
import 'package:hero_mart/src/features/assistant/data/datasources/assistant_voice_data_source.dart';
import 'package:hero_mart/src/features/assistant/data/datasources/assistant_voice_settings_local_data_source.dart';
import 'package:hero_mart/src/features/assistant/data/mappers/assistant_voice_mapper.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_speech_signal_model.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_voice_update_model.dart';
import 'package:hero_mart/src/features/assistant/data/repositories/assistant_voice_repository_impl.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_access.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_event.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_language.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_problem.dart';

/// A speech recognizer the test speaks through: [listen] reports the
/// microphone open (both platforms do), everything else the test emits.
class _FakeRecognizer implements AssistantSpeechRecognizer {
  AssistantSpeechPermissionModel permissionNow =
      AssistantSpeechPermissionModel.denied;
  AssistantSpeechPermissionModel permissionAnswer =
      AssistantSpeechPermissionModel.granted;
  bool initializes = true;
  bool listenStarts = true;
  bool opensOnListen = true;
  List<String> locales = const ['en-GB', 'en-US', 'ar-SA', 'ar-KW'];

  @override
  bool isApple = false;

  @override
  List<String> deviceLocaleIds = const [];

  final List<String?> listens = [];
  int permissionRequests = 0;
  int initializeCalls = 0;
  int localeReads = 0;
  int stops = 0;
  int cancels = 0;
  final StreamController<AssistantSpeechSignalModel> _signals =
      StreamController<AssistantSpeechSignalModel>.broadcast(sync: true);

  void emit(AssistantSpeechSignalModel signal) => _signals.add(signal);

  void words(String text, {bool isFinal = false}) =>
      emit(AssistantSpeechWords(text, isFinal: isFinal));

  /// Android's end of a session: the mic closes, then "done".
  void sessionEnds() {
    emit(const AssistantSpeechClosed());
    emit(const AssistantSpeechEnded());
  }

  @override
  Future<AssistantSpeechPermissionModel> permission() async => permissionNow;

  @override
  Future<AssistantSpeechPermissionModel> requestPermission() async {
    permissionRequests++;
    return permissionAnswer;
  }

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return initializes;
  }

  @override
  Future<List<String>> localeIds() async {
    localeReads++;
    return locales;
  }

  @override
  Future<bool> listen({String? localeId}) async {
    listens.add(localeId);
    if (listenStarts && opensOnListen) {
      scheduleMicrotask(() => emit(const AssistantSpeechOpened()));
    }
    return listenStarts;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<bool> openSettings() async => true;

  @override
  Stream<AssistantSpeechSignalModel> get signals => _signals.stream;
}

void main() {
  late _FakeRecognizer recognizer;
  late AssistantVoiceDataSourceImpl source;

  const reopen = Duration(milliseconds: 5);
  const lateWords = Duration(milliseconds: 40);
  const finishGrace = Duration(milliseconds: 80);
  const openTimeout = Duration(milliseconds: 60);

  setUp(() {
    recognizer = _FakeRecognizer();
    source = AssistantVoiceDataSourceImpl(
      recognizer,
      reopenDelay: reopen,
      lateWordsGrace: lateWords,
      finishGrace: finishGrace,
      openTimeout: openTimeout,
    );
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);
  Future<void> wait(Duration duration) => Future<void>.delayed(duration);

  /// Starts a take and waits for its microphone to open.
  Future<List<AssistantVoiceUpdateModel>> listening({
    String language = 'en',
    void Function()? onDone,
  }) async {
    final updates = <AssistantVoiceUpdateModel>[];
    source.listen(languageCode: language).listen(updates.add, onDone: onDone);
    await flush();
    await flush();
    return updates;
  }

  List<AssistantVoiceUpdateModel> withoutLevels(
    List<AssistantVoiceUpdateModel> updates,
  ) => updates.where((update) => update is! AssistantVoiceLevelModel).toList();

  group('access', () {
    test('asking: refused, blocked, granted, or no recognizer', () async {
      recognizer.permissionAnswer = AssistantSpeechPermissionModel.denied;
      expect(await source.requestAccess(), AssistantVoiceAccessModel.denied);
      recognizer.permissionAnswer = AssistantSpeechPermissionModel.blocked;
      expect(await source.requestAccess(), AssistantVoiceAccessModel.blocked);
      expect(recognizer.initializeCalls, 0);

      recognizer.permissionAnswer = AssistantSpeechPermissionModel.granted;
      expect(await source.requestAccess(), AssistantVoiceAccessModel.granted);
      recognizer.initializes = false;
      expect(
        await source.requestAccess(),
        AssistantVoiceAccessModel.unavailable,
      );
    });

    test('preparing asks nothing; when already allowed it readies the '
        'recognizer and its languages', () async {
      expect(await source.prepare(), isNull);
      recognizer.permissionNow = AssistantSpeechPermissionModel.blocked;
      expect(await source.prepare(), AssistantVoiceAccessModel.blocked);
      expect(recognizer.initializeCalls, 0);

      recognizer.permissionNow = AssistantSpeechPermissionModel.granted;
      expect(await source.prepare(), AssistantVoiceAccessModel.granted);
      expect(recognizer.initializeCalls, 1);
      expect(recognizer.localeReads, 1);
      expect(recognizer.permissionRequests, 0);
    });
  });

  group('recognizer language', () {
    test('Kuwait first, then the other preferred regions, then any', () {
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['ar-EG', 'ar-KW'], 'ar'),
        'ar-KW',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['ar_EG', 'ar_SA'], 'ar'),
        'ar_SA',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['ar-LB', 'en-US'], 'ar'),
        'ar-LB',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['en-GB', 'en-US'], 'en'),
        'en-US',
      );
    });

    test('nothing listed in the language: a sensible default', () {
      expect(AssistantVoiceDataSourceImpl.pickLocale(['en-US'], 'ar'), 'ar-KW');
      expect(AssistantVoiceDataSourceImpl.pickLocale(const [], 'en'), 'en-US');
      expect(AssistantVoiceDataSourceImpl.pickLocale(const [], 'fr'), isNull);
    });

    test('a take listens in the picked language', () async {
      await listening(language: 'ar');
      expect(recognizer.listens, ['ar-KW']);
    });

    test('Apple knows one Arabic — Saudi — whatever its list says', () {
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(
          ['ar-KW', 'ar-SA', 'en-GB'],
          'ar',
          apple: true,
          device: ['ar-KW'],
        ),
        'ar-SA',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['en-GB'], 'en', apple: true),
        'en-US',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(const [], 'fr', apple: true),
        isNull,
      );
    });

    test('an iPhone set to Arabic (Kuwait) still listens in ar-SA', () async {
      recognizer
        ..isApple = true
        ..deviceLocaleIds = ['ar-KW'];
      await listening(language: 'ar');
      expect(recognizer.listens, ['ar-SA']);
    });

    test('the phone\'s own region for the language comes first — when a '
        'known one', () {
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(
          ['ar_SA'],
          'ar',
          device: ['en-US', 'ar-EG'],
        ),
        'ar-EG',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(
          ['ar_SA'],
          'ar',
          device: ['ar-SD'],
        ),
        'ar_SA',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(
          ['en_US'],
          'en',
          device: ['ar-KW', 'en-GB'],
        ),
        'en-GB',
      );
    });

    test('a listed language with no real region is never asked for', () {
      // The plugin lists the phone's own language first: `ar_` when it has
      // no region, which reaches the recognizer as the broken tag `ar-`.
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['ar_', 'en_US'], 'ar'),
        'ar-KW',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['ar_001'], 'ar'),
        'ar-KW',
      );
      expect(
        AssistantVoiceDataSourceImpl.pickLocale(['ar'], 'ar', device: ['ar']),
        'ar-KW',
      );
    });
  });

  group('one take', () {
    test(
      'words are stitched across the sessions Android ends on silence',
      () async {
        final updates = await listening();
        recognizer
          ..words('I want')
          ..words('I want milk', isFinal: true)
          ..sessionEnds();
        await wait(reopen * 4);
        expect(recognizer.listens, hasLength(2));

        await flush();
        recognizer.words('and eggs', isFinal: true);
        unawaited(source.finish());
        await flush();
        recognizer.sessionEnds();
        await flush();

        expect(withoutLevels(updates), const [
          AssistantVoiceHeardModel('I want'),
          AssistantVoiceHeardModel('I want milk'),
          AssistantVoiceHeardModel('I want milk and eggs'),
          AssistantVoiceDoneModel('I want milk and eggs'),
        ]);
        expect(recognizer.stops, 1);
      },
    );

    test('after a stop it waits for the last words Android sends after '
        '"done"', () async {
      final updates = await listening();
      recognizer.words('milk');
      unawaited(source.finish());
      await flush();
      recognizer.sessionEnds();
      await flush();
      expect(updates.last, isNot(isA<AssistantVoiceDoneModel>()));

      recognizer.words('milk please', isFinal: true);
      await flush();
      expect(updates.last, const AssistantVoiceDoneModel('milk please'));
    });

    test('no last words at all: the stop settles on what was heard', () async {
      final updates = await listening();
      recognizer.words('bread');
      unawaited(source.finish());
      await flush();
      recognizer.sessionEnds();
      await wait(finishGrace * 2);
      expect(updates.last, const AssistantVoiceDoneModel('bread'));
    });

    test('a stop before the microphone opened ends at once', () async {
      recognizer.opensOnListen = false;
      final updates = <AssistantVoiceUpdateModel>[];
      source.listen(languageCode: 'en').listen(updates.add);
      await flush();
      await source.finish();
      await flush();
      expect(updates, const [AssistantVoiceDoneModel('')]);
      expect(recognizer.cancels, 1);
      expect(recognizer.stops, 0);
    });

    test('nothing said yet: the microphone reopens quietly', () async {
      final updates = await listening();
      recognizer
        ..emit(const AssistantSpeechError('error_speech_timeout'))
        ..sessionEnds();
      await wait(reopen * 4);
      expect(recognizer.listens, hasLength(2));
      expect(updates, isEmpty);
    });

    test('a busy recognizer is retried a few times, then gives up', () async {
      final updates = await listening();
      for (var i = 0; i <= AssistantVoiceDataSourceImpl.maxReopens; i++) {
        recognizer
          ..emit(const AssistantSpeechError('error_busy'))
          ..sessionEnds();
        await wait(reopen * (i + 3));
      }
      await flush();
      expect(
        recognizer.listens,
        hasLength(AssistantVoiceDataSourceImpl.maxReopens + 1),
      );
      expect(
        updates.last,
        const AssistantVoiceFailedModel(AssistantSpeechErrorKind.retry),
      );
    });

    test('a recognizer that never opens is retried like a busy one', () async {
      recognizer.opensOnListen = false;
      source.listen(languageCode: 'en').listen((_) {});
      await wait(openTimeout + reopen * 4);
      expect(recognizer.listens.length, greaterThanOrEqualTo(2));
      expect(recognizer.cancels, greaterThanOrEqualTo(1));
    });

    test('a lasting failure keeps the words heard', () async {
      final updates = await listening();
      recognizer
        ..words('half a', isFinal: true)
        ..sessionEnds();
      await wait(reopen * 4);
      recognizer
        ..words('list')
        ..emit(const AssistantSpeechError('error_network'));
      await flush();
      expect(
        updates.last,
        const AssistantVoiceFailedModel(
          AssistantSpeechErrorKind.network,
          text: 'half a list',
        ),
      );
      expect(recognizer.cancels, 1);
    });

    test('a session\'s words settled after the next one started replace '
        'its words — never said twice', () async {
      final updates = await listening();
      recognizer.opensOnListen = false;
      recognizer
        ..words('I want milk')
        ..sessionEnds();
      // No last words within the grace: the take moves on and reopens.
      await wait(lateWords + reopen * 4);
      expect(recognizer.listens, hasLength(2));

      // iOS settles the old session while the new microphone is starting.
      recognizer
        ..words('I want milk please', isFinal: true)
        ..emit(const AssistantSpeechOpened())
        ..words('and eggs', isFinal: true);
      unawaited(source.finish());
      await flush();
      recognizer.sessionEnds();
      await flush();

      expect(withoutLevels(updates), const [
        AssistantVoiceHeardModel('I want milk'),
        AssistantVoiceHeardModel('I want milk please'),
        AssistantVoiceHeardModel('I want milk please and eggs'),
        AssistantVoiceDoneModel('I want milk please and eggs'),
      ]);
    });

    test('words before a take\'s microphone first opens are an earlier '
        'take\'s: dropped', () async {
      recognizer.opensOnListen = false;
      final updates = <AssistantVoiceUpdateModel>[];
      source.listen(languageCode: 'en').listen(updates.add);
      await flush();
      recognizer
        ..words('old words', isFinal: true)
        ..emit(const AssistantSpeechOpened())
        ..words('new');
      await flush();
      expect(updates, const [AssistantVoiceHeardModel('new')]);
    });

    test('a stop after the microphone closed still waits for the words '
        'on their way', () async {
      final updates = await listening();
      // A recognizer that sends no partial words: closed, final still due.
      recognizer.emit(const AssistantSpeechClosed());
      await flush();
      unawaited(source.finish());
      await flush();
      expect(updates, isEmpty);

      recognizer.words('two apples', isFinal: true);
      await flush();
      expect(updates.last, const AssistantVoiceDoneModel('two apples'));
    });

    test('loudness passes through only while the microphone is open', () async {
      final updates = await listening();
      recognizer.emit(const AssistantSpeechLoudness(0.6));
      recognizer.emit(const AssistantSpeechClosed());
      recognizer.emit(const AssistantSpeechLoudness(0.9));
      await flush();
      expect(updates, const [AssistantVoiceLevelModel(0.6)]);
    });

    test(
      'a cancel drops the words and the stream ends without a result',
      () async {
        var closed = false;
        final updates = await listening(onDone: () => closed = true);
        recognizer.words('secret');
        await source.cancel();
        recognizer.words('secret words', isFinal: true);
        await flush();
        expect(closed, isTrue);
        expect(updates, const [AssistantVoiceHeardModel('secret')]);
        expect(recognizer.cancels, 1);
      },
    );

    test('a new message drops the one before', () async {
      var firstClosed = false;
      await listening(onDone: () => firstClosed = true);
      final second = await listening();
      expect(firstClosed, isTrue);
      // The new microphone opens once the recognizer let the first one go.
      await wait(reopen * 3);
      recognizer.words('second', isFinal: true);
      await flush();
      expect(second, const [AssistantVoiceHeardModel('second')]);
    });

    test('a take that replaces a live one (the language switched) opens '
        'once the recognizer let the old one go: the old session\'s last '
        'reports are not the new one\'s', () async {
      await listening();
      recognizer.words('and a bee');
      final updates = <AssistantVoiceUpdateModel>[];
      source.listen(languageCode: 'ar').listen(updates.add);
      await flush();
      expect(recognizer.cancels, 1);
      expect(recognizer.listens, ['en-US']);

      // Android reports the cancelled session's end as it answers the cancel.
      recognizer
        ..words('and a bee halib', isFinal: true)
        ..sessionEnds();
      await wait(reopen * 3);
      expect(recognizer.listens, ['en-US', 'ar-KW']);

      recognizer.words('أبي حليب');
      await wait(lateWords + reopen * 4);
      expect(recognizer.listens, hasLength(2));
      expect(updates, const [AssistantVoiceHeardModel('أبي حليب')]);
    });

    test('a dropped session\'s end reported after the next microphone was '
        'asked for (iOS, late) does not end the new session', () async {
      await listening();
      recognizer.opensOnListen = false;
      final updates = <AssistantVoiceUpdateModel>[];
      source.listen(languageCode: 'ar').listen(updates.add);
      await wait(reopen * 3);
      expect(recognizer.listens, hasLength(2));

      recognizer
        ..sessionEnds()
        ..emit(const AssistantSpeechOpened())
        ..words('أبي');
      await wait(lateWords + reopen * 4);
      expect(recognizer.listens, hasLength(2));

      recognizer.words('أبي حليب', isFinal: true);
      unawaited(source.finish());
      await flush();
      recognizer.sessionEnds();
      await flush();
      expect(updates, const [
        AssistantVoiceHeardModel('أبي'),
        AssistantVoiceHeardModel('أبي حليب'),
        AssistantVoiceDoneModel('أبي حليب'),
      ]);
    });

    test('dropping the subscription drops the take', () async {
      final subscription = source.listen(languageCode: 'en').listen((_) {});
      await flush();
      await subscription.cancel();
      expect(recognizer.cancels, 1);
    });
  });

  group('recognizer reports', () {
    test('error codes fall into what the take does with them', () {
      AssistantSpeechErrorKind kind(String code) =>
          AssistantSpeechError.kindOf(code);
      expect(kind('error_no_match'), AssistantSpeechErrorKind.noSpeech);
      expect(kind('error_speech_timeout'), AssistantSpeechErrorKind.noSpeech);
      expect(kind('error_busy'), AssistantSpeechErrorKind.retry);
      expect(kind('error_client'), AssistantSpeechErrorKind.retry);
      expect(kind('error_retry'), AssistantSpeechErrorKind.retry);
      expect(kind('error_network'), AssistantSpeechErrorKind.network);
      expect(kind('error_server'), AssistantSpeechErrorKind.network);
      expect(
        kind('error_language_unavailable'),
        AssistantSpeechErrorKind.language,
      );
      expect(
        kind('error_assets_not_installed'),
        AssistantSpeechErrorKind.language,
      );
      expect(kind('error_permission'), AssistantSpeechErrorKind.permission);
      expect(kind('error_request_cancelled'), AssistantSpeechErrorKind.ignore);
      expect(kind('error_unknown (12)'), AssistantSpeechErrorKind.other);
    });

    test('loudness maps each platform onto 0..1', () {
      double level(double raw, TargetPlatform platform) =>
          SpeechToTextRecognizer.normalizeLevel(raw, platform);
      expect(level(-2, TargetPlatform.android), 0);
      expect(level(10, TargetPlatform.android), 1);
      expect(level(4, TargetPlatform.android), closeTo(0.5, 0.001));
      expect(level(40, TargetPlatform.android), 1);
      expect(level(-80, TargetPlatform.iOS), 0);
      expect(level(-30, TargetPlatform.iOS), closeTo(0.5, 0.001));
      expect(level(double.nan, TargetPlatform.iOS), 0);
    });
  });

  group('mapper and repository', () {
    test('updates become events; error kinds become problems', () {
      expect(
        const AssistantVoiceHeardModel('hi').toEntity(),
        const AssistantVoiceHeard('hi'),
      );
      expect(
        const AssistantVoiceDoneModel('hi').toEntity(),
        const AssistantVoiceDone('hi'),
      );
      expect(
        const AssistantVoiceFailedModel(
          AssistantSpeechErrorKind.network,
          text: 'x',
        ).toEntity(),
        const AssistantVoiceFailed(AssistantVoiceProblem.network, text: 'x'),
      );
      expect(
        const AssistantVoiceFailedModel(AssistantSpeechErrorKind.retry)
            .toEntity(),
        const AssistantVoiceFailed(AssistantVoiceProblem.busy),
      );
      expect(
        AssistantVoiceAccessModel.unavailable.toEntity(),
        AssistantVoiceAccess.unavailable,
      );
    });

    test('the repository maps the take and wraps every call', () async {
      recognizer.permissionAnswer = AssistantSpeechPermissionModel.granted;
      final repository = AssistantVoiceRepositoryImpl(
        source,
        AssistantVoiceSettingsLocalDataSourceImpl(_MemoryStorage()),
      );
      expect(
        await repository.requestAccess(),
        const Right<Failure, AssistantVoiceAccess>(
          AssistantVoiceAccess.granted,
        ),
      );
      final events = <AssistantVoiceEvent>[];
      repository.listen(languageCode: 'en').listen(events.add);
      await flush();
      await flush();
      recognizer.words('tea', isFinal: true);
      unawaited(repository.finish());
      await flush();
      recognizer.sessionEnds();
      await flush();
      expect(events, const [
        AssistantVoiceHeard('tea'),
        AssistantVoiceDone('tea'),
      ]);
      expect(await repository.cancel(), const Right<Failure, Unit>(unit));
    });

    test(
      'a broken recognizer comes back as a failure, never an exception',
      () async {
        final repository = AssistantVoiceRepositoryImpl(
          _BrokenSource(),
          AssistantVoiceSettingsLocalDataSourceImpl(_MemoryStorage()),
        );
        expect(await repository.requestAccess(), isA<Left<Failure, dynamic>>());
        expect(await repository.finish(), isA<Left<Failure, dynamic>>());
        await expectLater(
          repository.listen(languageCode: 'en'),
          emitsError(isA<UnexpectedFailure>()),
        );
      },
    );

    test('the chosen language is kept on the device; a code this app no '
        'longer knows counts as none', () async {
      final storage = _MemoryStorage();
      final repository = AssistantVoiceRepositoryImpl(
        source,
        AssistantVoiceSettingsLocalDataSourceImpl(storage),
      );
      expect(
        await repository.savedLanguage(),
        const Right<Failure, AssistantVoiceLanguage?>(null),
      );
      expect(
        await repository.saveLanguage(AssistantVoiceLanguage.arabic),
        const Right<Failure, Unit>(unit),
      );
      expect(
        storage.values[AssistantVoiceSettingsLocalDataSourceImpl.languageKey],
        'ar',
      );
      expect(
        await repository.savedLanguage(),
        const Right<Failure, AssistantVoiceLanguage?>(
          AssistantVoiceLanguage.arabic,
        ),
      );

      storage.values[AssistantVoiceSettingsLocalDataSourceImpl.languageKey] =
          'fr';
      expect(
        await repository.savedLanguage(),
        const Right<Failure, AssistantVoiceLanguage?>(null),
      );
    });

    test('a language that could not be stored is a cache failure', () async {
      final storage = _MemoryStorage()..failWrites = true;
      final repository = AssistantVoiceRepositoryImpl(
        source,
        AssistantVoiceSettingsLocalDataSourceImpl(storage),
      );
      final result = await repository.saveLanguage(
        AssistantVoiceLanguage.english,
      );
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<CacheFailure>(),
      );
    });
  });
}

/// `LocalStorage` over a map; [failWrites] makes every write report `false`.
class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = {};
  bool failWrites = false;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<bool> setBool(String key, {required bool value}) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

/// A datasource whose recognizer has gone away mid-call.
class _BrokenSource implements AssistantVoiceDataSource {
  static final StateError _gone = StateError('recognizer gone');

  @override
  Future<AssistantVoiceAccessModel?> prepare() => throw _gone;

  @override
  Future<AssistantVoiceAccessModel> requestAccess() => throw _gone;

  @override
  Stream<AssistantVoiceUpdateModel> listen({required String languageCode}) =>
      Stream.error(_gone);

  @override
  Future<void> finish() => throw _gone;

  @override
  Future<void> cancel() => throw _gone;

  @override
  Future<bool> openSettings() => throw _gone;
}
