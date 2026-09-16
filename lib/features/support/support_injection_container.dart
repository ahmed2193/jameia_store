import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/support_local_data_source.dart';
import 'data/repositories/support_repository_impl.dart';
import 'domain/repositories/support_repository.dart';
import 'presentation/cubit/customer_service_cubit.dart';
import 'presentation/cubit/customer_service_question_cubit.dart';
import 'presentation/cubit/im_chat_cubit.dart';

/// Support feature DI — mirrors the cart template (offline local chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). Cubits are `registerFactory` (fresh per screen);
/// use cases / repository / datasource are `registerLazySingleton`.
void initSupportFeature() {
  if (sl.isRegistered<SupportRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<SupportLocalDataSource>(
      () => SupportLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(local: sl<SupportLocalDataSource>()));

  // Presentation (page-scoped cubits) — depend on the repository directly (the
  // pass-through use cases were collapsed).
  sl.registerFactory(() => CustomerServiceCubit(sl<SupportRepository>()));
  sl.registerFactory(
      () => CustomerServiceQuestionCubit(sl<SupportRepository>()));
  sl.registerFactory(() => ImChatCubit(sl<SupportRepository>()));
}
