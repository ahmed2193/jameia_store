import '../../config/di/service_locator.dart';
import '../../core/domain/entities/hero_address_entity.dart';
import 'data/datasources/address_local_data_source.dart';
import 'data/datasources/address_remote_data_source.dart';
import 'data/repositories/address_repository_impl.dart';
import 'domain/repositories/address_repository.dart';
import 'domain/usecases/add_address_usecase.dart';
import 'domain/usecases/clear_cached_addresses_usecase.dart';
import 'domain/usecases/delete_address_usecase.dart';
import 'domain/usecases/get_addresses_usecase.dart';
import 'domain/usecases/get_cached_addresses_usecase.dart';
import 'domain/usecases/save_cached_addresses_usecase.dart';
import 'domain/usecases/update_address_usecase.dart';
import 'presentation/cubit/address_book_cubit.dart';
import 'presentation/cubit/address_edit_cubit.dart';

/// Address feature DI — the customer address book over the Hero API
/// (`/v1/account/addresses`) with its device copy in `LocalStorage`. Depends
/// on the core `ApiConsumer` and `LocalStorage` registered by
/// `setupServiceLocator` before any feature init.
void initAddressFeature() {
  if (sl.isRegistered<AddressRepository>()) return; // idempotent

  sl
    // Data
    ..registerLazySingleton<AddressRemoteDataSource>(
      () => AddressRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AddressLocalDataSource>(
      () => AddressLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AddressRepository>(
      () => AddressRepositoryImpl(remote: sl(), local: sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetCachedAddressesUseCase(sl()))
    ..registerLazySingleton(() => GetAddressesUseCase(sl()))
    ..registerLazySingleton(() => AddAddressUseCase(sl()))
    ..registerLazySingleton(() => UpdateAddressUseCase(sl()))
    ..registerLazySingleton(() => DeleteAddressUseCase(sl()))
    ..registerLazySingleton(() => SaveCachedAddressesUseCase(sl()))
    ..registerLazySingleton(() => ClearCachedAddressesUseCase(sl()))
    // Presentation — the book is app-global (provided once above
    // MaterialApp.router via AppGlobalCubits); the edit form takes the address
    // being edited and whether it is the customer's first one.
    ..registerFactory(
      () => AddressBookCubit(
        getCached: sl(),
        getAddresses: sl(),
        updateAddress: sl(),
        deleteAddress: sl(),
        saveCache: sl(),
        clearCache: sl(),
      ),
    )
    ..registerFactoryParam<AddressEditCubit, HeroAddressEntity?, bool?>(
      (original, isFirstAddress) => AddressEditCubit(
        addAddress: sl(),
        updateAddress: sl(),
        original: original,
        isFirstAddress: isFirstAddress ?? false,
      ),
    );
}
