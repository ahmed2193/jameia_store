import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/jameia_address_entity.dart';

/// The customer's saved addresses as the app shows them: the default address
/// first, the rest in server order. Every change returns a new book.
class AddressBook extends Equatable {
  const AddressBook._(this.addresses);

  /// Orders [addresses] (e.g. a server list): the default one moves to the top.
  factory AddressBook.of(List<JameiaAddressEntity> addresses) =>
      AddressBook._(_defaultFirst(addresses));

  static const AddressBook empty = AddressBook._(<JameiaAddressEntity>[]);

  final List<JameiaAddressEntity> addresses;

  bool get isEmpty => addresses.isEmpty;

  /// Where to deliver when nothing else was picked: the default address, else
  /// the first one.
  JameiaAddressEntity? get defaultAddress =>
      flaggedDefault ?? (addresses.isEmpty ? null : addresses.first);

  /// The address flagged `isDefault`, without the first-address fallback.
  JameiaAddressEntity? get flaggedDefault {
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return null;
  }

  JameiaAddressEntity? byId(String id) {
    for (final address in addresses) {
      if (address.id == id) return address;
    }
    return null;
  }

  /// Adds [address] or replaces the one with its id. A customer has one
  /// default address, so a default [address] clears the flag on the others.
  AddressBook upsert(JameiaAddressEntity address) {
    final exists = byId(address.id) != null;
    return AddressBook.of([
      for (final current in addresses)
        if (current.id == address.id)
          address
        else if (address.isDefault && current.isDefault)
          current.copyWith(isDefault: false)
        else
          current,
      if (!exists) address,
    ]);
  }

  /// With [id] as the one default address; `null` or an unknown id leaves
  /// none flagged.
  AddressBook withDefault(String? id) => AddressBook.of([
    for (final address in addresses)
      if (address.isDefault == (address.id == id))
        address
      else
        address.copyWith(isDefault: address.id == id),
  ]);

  /// Without the address [id]; unknown ids leave the book unchanged.
  AddressBook remove(String id) {
    if (byId(id) == null) return this;
    return AddressBook._(
      List.unmodifiable([
        for (final address in addresses)
          if (address.id != id) address,
      ]),
    );
  }

  static List<JameiaAddressEntity> _defaultFirst(
    List<JameiaAddressEntity> addresses,
  ) {
    final index = addresses.indexWhere((address) => address.isDefault);
    if (index <= 0) return List.unmodifiable(addresses);
    return List.unmodifiable([
      addresses[index],
      ...addresses.take(index),
      ...addresses.skip(index + 1),
    ]);
  }

  @override
  List<Object?> get props => [addresses];
}
