import '../../config/di/service_locator.dart';
import 'data/datasources/assistant_remote_data_source.dart';
import 'data/repositories/assistant_repository_impl.dart';
import 'domain/repositories/assistant_repository.dart';
import 'domain/usecases/confirm_assistant_action_usecase.dart';
import 'domain/usecases/get_assistant_availability_usecase.dart';
import 'domain/usecases/get_assistant_conversation_usecase.dart';
import 'domain/usecases/get_assistant_conversations_usecase.dart';
import 'domain/usecases/rate_assistant_message_usecase.dart';
import 'domain/usecases/request_assistant_handoff_usecase.dart';
import 'domain/usecases/send_assistant_message_usecase.dart';
import 'presentation/cubit/assistant_availability_cubit.dart';
import 'presentation/cubit/assistant_chat_cubit.dart';
import 'presentation/cubit/assistant_history_cubit.dart';

/// Assistant feature DI — the streaming shopping chat on `/v1/assistant/*`.
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
    // Domain
    ..registerLazySingleton(() => GetAssistantAvailabilityUseCase(sl()))
    ..registerLazySingleton(() => GetAssistantConversationsUseCase(sl()))
    ..registerLazySingleton(() => GetAssistantConversationUseCase(sl()))
    ..registerLazySingleton(() => SendAssistantMessageUseCase(sl()))
    ..registerLazySingleton(() => ConfirmAssistantActionUseCase(sl()))
    ..registerLazySingleton(() => RequestAssistantHandoffUseCase(sl()))
    ..registerLazySingleton(() => RateAssistantMessageUseCase(sl()))
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
    ..registerFactory(() => AssistantHistoryCubit(getConversations: sl()));
}
