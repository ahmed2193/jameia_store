import '../../config/di/service_locator.dart';
import 'data/datasources/assistant_nudge_local_data_source.dart';
import 'data/datasources/assistant_remote_data_source.dart';
import 'data/repositories/assistant_nudge_repository_impl.dart';
import 'data/repositories/assistant_repository_impl.dart';
import 'domain/repositories/assistant_nudge_repository.dart';
import 'domain/repositories/assistant_repository.dart';
import 'domain/usecases/claim_assistant_nudge_usecase.dart';
import 'domain/usecases/complete_assistant_onboarding_usecase.dart';
import 'domain/usecases/confirm_assistant_action_usecase.dart';
import 'domain/usecases/get_assistant_availability_usecase.dart';
import 'domain/usecases/get_assistant_conversation_usecase.dart';
import 'domain/usecases/get_assistant_conversations_usecase.dart';
import 'domain/usecases/get_assistant_launcher_hidden_usecase.dart';
import 'domain/usecases/get_assistant_onboarded_usecase.dart';
import 'domain/usecases/hide_assistant_launcher_usecase.dart';
import 'domain/usecases/rate_assistant_message_usecase.dart';
import 'domain/usecases/record_assistant_nudge_outcome_usecase.dart';
import 'domain/usecases/request_assistant_handoff_usecase.dart';
import 'domain/usecases/send_assistant_message_usecase.dart';
import 'presentation/cubit/assistant_availability_cubit.dart';
import 'presentation/cubit/assistant_buddy_cubit.dart';
import 'presentation/cubit/assistant_chat_cubit.dart';
import 'presentation/cubit/assistant_history_cubit.dart';

/// Assistant feature DI — the streaming shopping chat on `/v1/assistant/*`
/// and its buddy over the main shell (greeting log in `LocalStorage`).
/// Depends on the core `ApiConsumer` and `EventStreamClient` registered by
/// `setupServiceLocator` before any feature init.
void initAssistantFeature() {
  if (sl.isRegistered<AssistantRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<AssistantRemoteDataSource>(
      () => AssistantRemoteDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<AssistantRepository>(
      () => AssistantRepositoryImpl(sl()),
    )
    ..registerLazySingleton<AssistantNudgeLocalDataSource>(
      () => AssistantNudgeLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AssistantNudgeRepository>(
      () => AssistantNudgeRepositoryImpl(sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetAssistantAvailabilityUseCase(sl()))
    ..registerLazySingleton(() => GetAssistantConversationsUseCase(sl()))
    ..registerLazySingleton(() => GetAssistantConversationUseCase(sl()))
    ..registerLazySingleton(() => SendAssistantMessageUseCase(sl()))
    ..registerLazySingleton(() => ConfirmAssistantActionUseCase(sl()))
    ..registerLazySingleton(() => RequestAssistantHandoffUseCase(sl()))
    ..registerLazySingleton(() => RateAssistantMessageUseCase(sl()))
    ..registerLazySingleton(() => ClaimAssistantNudgeUseCase(sl()))
    ..registerLazySingleton(() => RecordAssistantNudgeOutcomeUseCase(sl()))
    ..registerLazySingleton(() => GetAssistantLauncherHiddenUseCase(sl()))
    ..registerLazySingleton(() => HideAssistantLauncherUseCase(sl()))
    ..registerLazySingleton(() => GetAssistantOnboardedUseCase(sl()))
    ..registerLazySingleton(() => CompleteAssistantOnboardingUseCase(sl()))
    // Presentation — chat and history are page-scoped; availability is
    // app-global (built by `AppGlobalCubits`), a factory like the others.
    ..registerFactory(() => AssistantAvailabilityCubit(getAvailability: sl()))
    ..registerFactory(
      () => AssistantChatCubit(
        getConversations: sl(),
        getConversation: sl(),
        send: sl(),
        confirm: sl(),
        rate: sl(),
        handOff: sl(),
      ),
    )
    ..registerFactory(() => AssistantHistoryCubit(getConversations: sl()))
    // The buddy (launcher, greeting and tour) lives with the main shell.
    ..registerFactory(
      () => AssistantBuddyCubit(
        claim: sl(),
        record: sl(),
        getHidden: sl(),
        hide: sl(),
        getOnboarded: sl(),
        completeOnboarding: sl(),
      ),
    );
}
