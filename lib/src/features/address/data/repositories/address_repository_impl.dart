import 'package:dartz/dartz.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/jameia_address_entity.dart';
import '../../domain/entities/region_options.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_local_data_source.dart';
import '../mappers/address_mapper.dart';
import '../mappers/service_region_mapper.dart';

/// Offline address repository — delegates every persisted read/write to the
/// [AddressLocalDataSource] (backed by [JameiaRepository]) and wraps the result in
/// `Either<Failure, T>`.
///
/// The mutations forward to the SAME `JameiaRepository` operations the cubits used
/// inline before the refactor, so the `shared_preferences` persistence and the
/// active-address notifier keep behaving identically.
class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl({required this.local});

  final AddressLocalDataSource local;

  @override
  Future<Either<Failure, List<JameiaAddressEntity>>> getAddresses() async {
    try {
      // Hoist the default address to the top to mirror Jameia's ordering.
      final sorted = [...local.addresses()]
        ..sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
      return Right(sorted.toEntities());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JameiaAddress>> addAddress(
    JameiaAddress address,
  ) async {
    try {
      return Right(local.upsertAddress(address));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JameiaAddress>> updateAddress(
    JameiaAddress address,
  ) async {
    try {
      return Right(local.upsertAddress(address));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAddress(String id) async {
    try {
      local.deleteAddress(id);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setPrimaryAddress(String id) async {
    try {
      local.selectActiveAddress(id);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RegionOptions>> getServiceRegions() async {
    try {
      return Right(
        RegionOptions(
          regions: local.serviceRegions().toEntities(),
          activeRegion: local.activeRegion(),
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> switchRegion(String region) async {
    try {
      local.switchRegion(region);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
