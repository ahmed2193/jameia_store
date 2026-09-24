import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/jameia_address_entity.dart';
import 'address_book.dart';

/// The address book saved on this device and the customer it was saved for
/// ([ownerId] is `null` when the session did not know the customer yet, e.g.
/// a launch while offline).
class CachedAddressBook extends Equatable {
  const CachedAddressBook({this.ownerId, this.addresses = const []});

  static const CachedAddressBook none = CachedAddressBook();

  final String? ownerId;
  final List<JameiaAddressEntity> addresses;

  AddressBook get book => AddressBook.of(addresses);

  /// `false` only when both ids are known and differ: the copy belongs to
  /// another customer and must not be shown.
  bool belongsTo(String? customerId) =>
      ownerId == null || customerId == null || ownerId == customerId;

  @override
  List<Object?> get props => [ownerId, addresses];
}
