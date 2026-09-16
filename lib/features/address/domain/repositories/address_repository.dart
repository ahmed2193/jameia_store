import 'package:dartz/dartz.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../entities/keeta_address_entity.dart';
import '../entities/region_options.dart';

/// Read + persist boundary for the saved-address book and the serviceable-region
/// picker. Offline, every method resolves against the in-memory
/// [KeetaRepository] (which owns the `shared_preferences`-backed address book +
/// the active-address / active-region notifiers); results are still wrapped in
/// `Either<Failure, T>` so the presentation layer handles failure uniformly.
///
/// READS return framework-free entities ([KeetaAddressEntity] / [RegionOptions]).
/// The WRITE methods still take/return the core [KeetaAddress] DTO: the editor
/// composes a fully-formed persistable row and the same row flows back out to
/// the list picker / checkout — a deliberate P2.9 boundary (the DTO is the
/// persistence payload, not an internal domain value).
abstract class AddressRepository {
  /// The saved-address book, default address hoisted to the top (KeeTa ordering).
  Future<Either<Failure, List<KeetaAddressEntity>>> getAddresses();

  /// Insert a new saved address (`saveOrUpdateV2`) — persists + records its
  /// coordinate. Returns the saved row.
  // TODO(P2.9-boundary): KeetaAddress DTO in/out — composed persistence payload
  // shared with the editor pop + list picker (checkout/home consume the core row).
  Future<Either<Failure, KeetaAddress>> addAddress(KeetaAddress address);

  /// Update an existing saved address (`UPDATEUSERADDRESS`) — persists + records
  /// its coordinate. Returns the saved row.
  // TODO(P2.9-boundary): KeetaAddress DTO in/out — composed persistence payload.
  Future<Either<Failure, KeetaAddress>> updateAddress(KeetaAddress address);

  /// Delete a saved address by id (`DELUSERADDRESS`) — persists + clears the
  /// active selection when it pointed at the deleted row.
  Future<Either<Failure, Unit>> deleteAddress(String id);

  /// Select the active delivery address (`homeSelectedUserAddress` + broadcast) —
  /// updates the active-address notifier + records its coordinate.
  Future<Either<Failure, Unit>> setPrimaryAddress(String id);

  /// The serviceable-region anchors + the currently-active region code.
  Future<Either<Failure, RegionOptions>> getServiceRegions();

  /// Commit a region switch (`switchRegion` + `com.keeta.changed.region`).
  Future<Either<Failure, Unit>> switchRegion(String region);
}
