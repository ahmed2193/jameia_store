import 'package:flutter/services.dart' show rootBundle;

import '../../config/di/service_locator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/domain/entities/geo_point_entity.dart';
import '../../core/domain/entities/hero_address_entity.dart';
import 'data/datasources/address_local_data_source.dart';
import 'data/datasources/address_remote_data_source.dart';
import 'data/datasources/device_location_data_source.dart';
import 'data/datasources/geocoder_data_source.dart';
import 'data/datasources/known_areas_local_data_source.dart';
import 'data/datasources/places_remote_data_source.dart';
import 'data/datasources/service_area_local_data_source.dart';
import 'data/repositories/address_repository_impl.dart';
import 'data/repositories/device_location_repository_impl.dart';
import 'data/repositories/places_repository_impl.dart';
import 'data/repositories/service_area_repository_impl.dart';
import 'domain/entities/new_address_seed.dart';
import 'domain/entities/pinned_place.dart';
import 'domain/repositories/address_repository.dart';
import 'domain/repositories/device_location_repository.dart';
import 'domain/repositories/places_repository.dart';
import 'domain/repositories/service_area_repository.dart';
import 'domain/usecases/add_address_usecase.dart';
import 'domain/usecases/clear_cached_addresses_usecase.dart';
import 'domain/usecases/delete_address_usecase.dart';
import 'domain/usecases/end_place_search_usecase.dart';
import 'domain/usecases/get_delivery_areas_usecase.dart';
import 'domain/usecases/get_addresses_usecase.dart';
import 'domain/usecases/get_cached_addresses_usecase.dart';
import 'domain/usecases/get_last_known_location_usecase.dart';
import 'domain/usecases/get_service_area_usecase.dart';
import 'domain/usecases/locate_device_usecase.dart';
import 'domain/usecases/locate_place_usecase.dart';
import 'domain/usecases/open_location_settings_usecase.dart';
import 'domain/usecases/resolve_pin_usecase.dart';
import 'domain/usecases/save_cached_addresses_usecase.dart';
import 'domain/usecases/search_places_usecase.dart';
import 'domain/usecases/update_address_usecase.dart';
import 'presentation/cubit/address_book_cubit.dart';
import 'presentation/cubit/address_edit_cubit.dart';
import 'presentation/cubit/address_picker_cubit.dart';
import 'presentation/cubit/place_search_cubit.dart';

/// Address feature DI — the customer address book over the Hero API
/// (`/v1/account/addresses`) with its device copy in `LocalStorage`, and the
/// map picker: the device's location, its geocoder, Google Places (New)
/// when the app was built with a Maps key, and where Hero delivers. Depends
/// on the core `ApiConsumer`, `ExternalApiConsumer` and `LocalStorage`
/// registered by `setupServiceLocator` before any feature init.
void initAddressFeature() {
  if (sl.isRegistered<AddressRepository>()) return; // idempotent

  final mapsKey = AppConstants.mapsApiKey;
  if (mapsKey.isNotEmpty) {
    // Billed per session: only when a key was given at build time.
    sl.registerLazySingleton<PlacesRemoteDataSource>(
      () => PlacesRemoteDataSourceImpl(sl(), apiKey: mapsKey),
    );
  }

  sl
    // Data
    ..registerLazySingleton<AddressRemoteDataSource>(
      () => AddressRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AddressLocalDataSource>(
      () => AddressLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<DeviceLocationDataSource>(
      DeviceLocationDataSourceImpl.new,
    )
    ..registerLazySingleton<GeocoderDataSource>(GeocoderDataSourceImpl.new)
    ..registerLazySingleton<KnownAreasLocalDataSource>(
      KnownAreasLocalDataSourceImpl.new,
    )
    ..registerLazySingleton<ServiceAreaLocalDataSource>(
      () => ServiceAreaLocalDataSourceImpl(rootBundle),
    )
    ..registerLazySingleton<AddressRepository>(
      () => AddressRepositoryImpl(remote: sl(), local: sl()),
    )
    ..registerLazySingleton<PlacesRepository>(
      () => PlacesRepositoryImpl(
        geocoder: sl(),
        areas: sl(),
        google: sl.isRegistered<PlacesRemoteDataSource>() ? sl() : null,
      ),
    )
    ..registerLazySingleton<DeviceLocationRepository>(
      () => DeviceLocationRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ServiceAreaRepository>(
      () => ServiceAreaRepositoryImpl(sl()),
    )
    // Domain
    ..registerLazySingleton(() => GetCachedAddressesUseCase(sl()))
    ..registerLazySingleton(() => GetAddressesUseCase(sl()))
    ..registerLazySingleton(() => AddAddressUseCase(sl()))
    ..registerLazySingleton(() => UpdateAddressUseCase(sl()))
    ..registerLazySingleton(() => DeleteAddressUseCase(sl()))
    ..registerLazySingleton(() => SaveCachedAddressesUseCase(sl()))
    ..registerLazySingleton(() => ClearCachedAddressesUseCase(sl()))
    ..registerLazySingleton(() => ResolvePinUseCase(sl()))
    ..registerLazySingleton(() => SearchPlacesUseCase(sl(), sl()))
    ..registerLazySingleton(() => LocatePlaceUseCase(sl()))
    ..registerLazySingleton(() => EndPlaceSearchUseCase(sl()))
    ..registerLazySingleton(() => GetDeliveryAreasUseCase(sl()))
    ..registerLazySingleton(() => GetLastKnownLocationUseCase(sl()))
    ..registerLazySingleton(() => LocateDeviceUseCase(sl()))
    ..registerLazySingleton(() => OpenLocationSettingsUseCase(sl()))
    ..registerLazySingleton(() => GetServiceAreaUseCase(sl()))
    // Presentation — the book is app-global (provided once above
    // MaterialApp.router via AppGlobalCubits); the edit form takes the address
    // being edited, or what a new one starts with (NewAddressSeed: default
    // when it is the first, the signed-in customer's phone); the map picker
    // opens on the saved pin (null: a new address finds the device).
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
    ..registerFactoryParam<
      AddressEditCubit,
      HeroAddressEntity?,
      NewAddressSeed?
    >(
      (original, seed) => AddressEditCubit(
        addAddress: sl(),
        updateAddress: sl(),
        original: original,
        seed: seed ?? const NewAddressSeed(),
      ),
    )
    ..registerFactoryParam<AddressPickerCubit, PinnedPlace?, void>(
      (pinned, _) => AddressPickerCubit(
        resolvePin: sl(),
        lastKnown: sl(),
        locateDevice: sl(),
        openSettings: sl(),
        serviceArea: sl(),
        pinned: pinned,
      ),
    )
    ..registerFactoryParam<PlaceSearchCubit, GeoPointEntity?, void>(
      (near, _) => PlaceSearchCubit(
        searchPlaces: sl(),
        locatePlace: sl(),
        endSearch: sl(),
        deliveryAreas: sl(),
        near: near,
      ),
    );
}
