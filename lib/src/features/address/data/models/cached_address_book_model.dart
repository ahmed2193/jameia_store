import '../../../../core/error/exceptions.dart';
import 'address_model.dart';

/// The device copy of the address book as stored:
/// `{ "ownerId": "<customer _id>" | null, "addresses": [<API rows>] }`.
/// The rows keep the exact `GET /v1/account/addresses` shape.
class CachedAddressBookModel {
  const CachedAddressBookModel({this.ownerId, this.addresses = const []});

  static const String ownerIdKey = 'ownerId';
  static const String addressesKey = 'addresses';

  static const CachedAddressBookModel empty = CachedAddressBookModel();

  factory CachedAddressBookModel.fromJson(Object? json) {
    if (json is! Map) {
      throw ParsingException('address cache: unexpected ${json.runtimeType}');
    }
    final ownerId = json[ownerIdKey];
    final rows = json[addressesKey];
    return CachedAddressBookModel(
      ownerId: ownerId is String && ownerId.isNotEmpty ? ownerId : null,
      addresses: rows is List ? AddressModel.listFromJson(rows) : const [],
    );
  }

  final String? ownerId;
  final List<AddressModel> addresses;

  Map<String, dynamic> toJson() => <String, dynamic>{
    ownerIdKey: ownerId,
    addressesKey: [for (final address in addresses) address.toJson()],
  };
}
