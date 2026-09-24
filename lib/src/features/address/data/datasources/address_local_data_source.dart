import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/cached_address_book_model.dart';

/// The copy of the customer's address book on this device: the API rows plus
/// the customer they belong to, as JSON under one `LocalStorage` key. It lets
/// a launch show the book before the network answers and keeps it usable
/// offline. It is wiped when the session ends.
abstract class AddressLocalDataSource {
  /// The saved copy; [CachedAddressBookModel.empty] when nothing is saved.
  Future<CachedAddressBookModel> readAddresses();

  Future<void> saveAddresses(CachedAddressBookModel copy);

  /// Removes the copy, and the address books older app versions kept.
  Future<void> clear();
}

class AddressLocalDataSourceImpl implements AddressLocalDataSource {
  const AddressLocalDataSourceImpl(this._storage);

  /// Bump the version when the stored shape changes (and add the old key to
  /// [_retiredKeys]).
  static const String cacheKey = 'account.addresses.v2';

  /// Earlier device copies of the book, removed with the current one:
  /// `account.addresses.v1` (rows without an owner) and the offline book the
  /// catalogue persisted before addresses moved to the API — both may hold a
  /// previous customer's addresses and phone numbers.
  static const List<String> _retiredKeys = [
    'account.addresses.v1',
    'jameia.addressbook.v1',
  ];

  final LocalStorage _storage;

  @override
  Future<CachedAddressBookModel> readAddresses() async {
    final raw = _storage.getString(cacheKey);
    if (raw == null) return CachedAddressBookModel.empty;
    try {
      return CachedAddressBookModel.fromJson(jsonDecode(raw));
    } on FormatException catch (error) {
      throw CacheException('address cache unreadable: ${error.message}');
    } on ParsingException catch (error) {
      throw CacheException(error.message);
    }
  }

  @override
  Future<void> saveAddresses(CachedAddressBookModel copy) =>
      _guard(() => _storage.setString(cacheKey, jsonEncode(copy.toJson())));

  @override
  Future<void> clear() async {
    for (final key in [cacheKey, ..._retiredKeys]) {
      await _guard(() => _storage.remove(key));
    }
  }

  /// A failed or refused write surfaces as the data layer's [CacheException].
  static Future<void> _guard(Future<bool> Function() write) async {
    final bool written;
    try {
      written = await write();
    } on Exception catch (error) {
      throw CacheException('address cache write failed: $error');
    }
    if (!written) throw const CacheException('address cache write refused');
  }
}
