import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/address_draft.dart';
import '../entities/address_update.dart';
import '../entities/cached_address_book.dart';

/// The customer's address book on the jm3eia API plus its copy on this
/// device. Every API route is customer-only: a guest gets
/// `Left(UnauthorizedFailure)`.
///
/// The API calls never touch the device copy; the caller that owns the book
/// (`AddressBookCubit`) decides what to cache, so a reply that arrives after
/// sign-out can never be written back.
///
/// Reference: https://docs.jm3eia.store/developers/account.html
abstract class AddressRepository {
  /// The copy saved on this device and whose it is;
  /// [CachedAddressBook.none] when there is none.
  Future<Either<Failure, CachedAddressBook>> getCachedAddresses();

  /// Replaces the device copy with [addresses] (stored as the API rows) saved
  /// for the customer [ownerId] (`null` when not known yet).
  Future<Either<Failure, Unit>> saveCachedAddresses(
    List<JameiaAddressEntity> addresses, {
    String? ownerId,
  });

  /// Removes the device copy (sign-out, session expiry).
  Future<Either<Failure, Unit>> clearCachedAddresses();

  /// `GET /v1/account/addresses` — every saved address.
  Future<Either<Failure, List<JameiaAddressEntity>>> fetchAddresses();

  /// `POST /v1/account/addresses` — the created address.
  Future<Either<Failure, JameiaAddressEntity>> addAddress(AddressDraft draft);

  /// `PATCH /v1/account/addresses/:addressId` with the changed fields only —
  /// the updated address.
  Future<Either<Failure, JameiaAddressEntity>> updateAddress(
    String id,
    AddressUpdate update,
  );

  /// `DELETE /v1/account/addresses/:addressId`. An address the server no
  /// longer has (404) counts as deleted.
  Future<Either<Failure, Unit>> deleteAddress(String id);
}
