import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_access.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_event.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_language.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_policy.dart';
import 'package:hero_mart/src/features/assistant/domain/repositories/assistant_voice_repository.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/cancel_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/finish_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/get_assistant_voice_language_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/listen_to_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/open_assistant_voice_settings_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/prepare_assistant_voice_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/request_assistant_voice_access_usecase.dart';
import 'package:hero_mart/src/features/assistant/domain/usecases/save_assistant_voice_language_usecase.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_voice_cubit.dart';

/// An `AssistantVoiceRepository` the test drives: it answers access at once
/// (or holds it until [answerAccess] when [holdAccess]), and each [listen]
/// is a controller the test feeds words, levels and the ending into.
class FakeVoiceRepository implements AssistantVoiceRepository {
  AssistantVoiceAccess? prepared;
  Either<Failure, AssistantVoiceAccess> access = const Right(
    AssistantVoiceAccess.granted,
  );
  bool holdAccess = false;
  final List<Completer<Either<Failure, AssistantVoiceAccess>>> _held = [];
  int accessRequests = 0;
  Either<Failure, Unit> finishAnswer = const Right(unit);

  final List<StreamController<AssistantVoiceEvent>> takes = [];
  final List<String> languages = [];
  int finishes = 0;
  int cancels = 0;
  int settingsOpened = 0;

  /// The language the customer chose, as stored; every save lands here.
  AssistantVoiceLanguage? storedLanguage;
  final List<AssistantVoiceLanguage> savedLanguages = [];

  StreamController<AssistantVoiceEvent> get take => takes.last;

  /// Answers the access request still on hold.
  void answerAccess(Either<Failure, AssistantVoiceAccess> answer) =>
      _held.removeAt(0).complete(answer);

  @override
  Future<Either<Failure, AssistantVoiceAccess?>> prepare() async =>
      Right(prepared);

  @override
  Future<Either<Failure, AssistantVoiceAccess>> requestAccess() {
    accessRequests++;
    if (!holdAccess) return Future.value(access);
    final held = Completer<Either<Failure, AssistantVoiceAccess>>();
    _held.add(held);
    return held.future;
  }

  @override
  Stream<AssistantVoiceEvent> listen({required String languageCode}) {
    languages.add(languageCode);
    final controller = StreamController<AssistantVoiceEvent>();
    takes.add(controller);
    return controller.stream;
  }

  @override
  Future<Either<Failure, Unit>> finish() async {
    finishes++;
    return finishAnswer;
  }

  @override
  Future<Either<Failure, Unit>> cancel() async {
    cancels++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> openSettings() async {
    settingsOpened++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, AssistantVoiceLanguage?>> savedLanguage() async =>
      Right(storedLanguage);

  @override
  Future<Either<Failure, Unit>> saveLanguage(
    AssistantVoiceLanguage language,
  ) async {
    storedLanguage = language;
    savedLanguages.add(language);
    return const Right(unit);
  }
}

/// Test timings: a 10 ms clock, a 30 ms "mere tap", a 400 ms cap.
const AssistantVoicePolicy testVoicePolicy = AssistantVoicePolicy(
  accidentalTap: Duration(milliseconds: 30),
  maxLength: Duration(milliseconds: 400),
);
const Duration testVoiceTick = Duration(milliseconds: 10);

AssistantVoiceCubit voiceCubit(
  FakeVoiceRepository repository, {
  AssistantVoicePolicy policy = testVoicePolicy,
  Duration tick = testVoiceTick,
}) => AssistantVoiceCubit(
  prepare: PrepareAssistantVoiceUseCase(repository),
  requestAccess: RequestAssistantVoiceAccessUseCase(repository),
  listen: ListenToAssistantVoiceUseCase(repository),
  finish: FinishAssistantVoiceUseCase(repository),
  cancel: CancelAssistantVoiceUseCase(repository),
  openSettings: OpenAssistantVoiceSettingsUseCase(repository),
  savedLanguage: GetAssistantVoiceLanguageUseCase(repository),
  saveLanguage: SaveAssistantVoiceLanguageUseCase(repository),
  policy: policy,
  tick: tick,
);
