import '../../core/config/service_locator.dart';
import '../../core/data/keeta_repository.dart';
import 'data/datasources/address_local_data_source.dart';
import 'data/repositories/address_repository_impl.dart';
import 'domain/repositories/address_repository.dart';
import 'presentation/cubit/address_edit_cubit.dart';
import 'presentation/cubit/address_list_cubit.dart';
import 'presentation/cubit/choose_location_cubit.dart';

/// Address feature DI — mirrors the cart / support templates (offline local
/// chain over [KeetaRepository]).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [KeetaRepository]). Cubits are `registerFactory` (fresh per screen);
/// the address editor is resolved plain and seeded by the screen with the routed
/// address (`sl<AddressEditCubit>()..seed(initial)`). Repository / datasource are
/// `registerLazySingleton`.
///
/// The seven former pass-through use cases were collapsed (P2.9): each just
/// forwarded to the repository, so the cubits now depend on [AddressRepository]
/// directly. Every persisted read/write is still routed to the EXACT
/// [KeetaRepository] address operations the cubits used inline before the
/// refactor, so add / edit / delete / set-primary keep persisting across
/// restarts and the active-address notifier keeps updating.
void initAddressFeature() {
  if (sl.isRegistered<AddressRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<AddressLocalDataSource>(
      () => AddressLocalDataSourceImpl(sl<KeetaRepository>()));
  sl.registerLazySingleton<AddressRepository>(
      () => AddressRepositoryImpl(local: sl<AddressLocalDataSource>()));

  // Presentation (page-scoped cubits) — depend on the repository directly.
  sl.registerFactory(() => AddressListCubit(sl<AddressRepository>()));
  sl.registerFactory(() => ChooseLocationCubit(sl<AddressRepository>()));
  sl.registerFactory(() => AddressEditCubit(sl<AddressRepository>()));
}
