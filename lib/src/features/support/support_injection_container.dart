import '../../config/di/service_locator.dart';
import '../../core/data/hero_repository.dart';
import 'data/datasources/support_local_data_source.dart';
import 'data/datasources/support_remote_data_source.dart';
import 'data/repositories/support_repository_impl.dart';
import 'data/repositories/support_tickets_repository_impl.dart';
import 'domain/repositories/support_repository.dart';
import 'domain/repositories/support_tickets_repository.dart';
import 'domain/usecases/create_support_ticket_usecase.dart';
import 'domain/usecases/get_active_rider_name_usecase.dart';
import 'domain/usecases/get_faqs_usecase.dart';
import 'domain/usecases/get_support_categories_usecase.dart';
import 'domain/usecases/get_support_hub_usecase.dart';
import 'presentation/cubit/customer_service_cubit.dart';
import 'presentation/cubit/customer_service_question_cubit.dart';
import 'presentation/cubit/im_chat_cubit.dart';
import 'presentation/cubit/order_help_cubit.dart';

/// Support feature DI: the help hub over the loaded [HeroRepository], and
/// the order help page on the support tickets API. Cubits are
/// `registerFactory` (fresh per screen); use cases, repositories and
/// datasources are `registerLazySingleton`.
void initSupportFeature() {
  if (sl.isRegistered<SupportRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<SupportLocalDataSource>(
      () => SupportLocalDataSourceImpl(sl<HeroRepository>()),
    )
    ..registerLazySingleton<SupportRemoteDataSource>(
      () => SupportRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(sl()),
    )
    ..registerLazySingleton<SupportTicketsRepository>(
      () => SupportTicketsRepositoryImpl(sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetSupportHubUseCase(sl()))
    ..registerLazySingleton(() => GetFaqsUseCase(sl()))
    ..registerLazySingleton(() => GetActiveRiderNameUseCase(sl()))
    ..registerLazySingleton(() => GetSupportCategoriesUseCase(sl()))
    ..registerLazySingleton(() => CreateSupportTicketUseCase(sl()))
    // Presentation
    ..registerFactory(() => CustomerServiceCubit(sl()))
    ..registerFactory(() => CustomerServiceQuestionCubit(sl()))
    ..registerFactory(() => ImChatCubit(sl()))
    ..registerFactory(
      () => OrderHelpCubit(getCategories: sl(), createTicket: sl()),
    );
}
