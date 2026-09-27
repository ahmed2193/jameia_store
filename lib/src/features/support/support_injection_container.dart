import '../../config/di/service_locator.dart';
import '../../core/data/hero_repository.dart';
import 'data/datasources/support_local_data_source.dart';
import 'data/repositories/support_repository_impl.dart';
import 'domain/repositories/support_repository.dart';
import 'domain/usecases/get_active_rider_name_usecase.dart';
import 'domain/usecases/get_faqs_usecase.dart';
import 'domain/usecases/get_support_hub_usecase.dart';
import 'presentation/cubit/customer_service_cubit.dart';
import 'presentation/cubit/customer_service_question_cubit.dart';
import 'presentation/cubit/im_chat_cubit.dart';

/// Support feature DI (offline chain over the loaded [HeroRepository]).
/// Cubits are `registerFactory` (fresh per screen); use cases, repository and
/// datasource are `registerLazySingleton`.
void initSupportFeature() {
  if (sl.isRegistered<SupportRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<SupportLocalDataSource>(
      () => SupportLocalDataSourceImpl(sl<HeroRepository>()),
    )
    ..registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetSupportHubUseCase(sl()))
    ..registerLazySingleton(() => GetFaqsUseCase(sl()))
    ..registerLazySingleton(() => GetActiveRiderNameUseCase(sl()))
    // Presentation
    ..registerFactory(() => CustomerServiceCubit(sl()))
    ..registerFactory(() => CustomerServiceQuestionCubit(sl()))
    ..registerFactory(() => ImChatCubit(sl()));
}
