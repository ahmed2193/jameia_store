import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/address_label.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/jameia_address_entity.dart';
import 'address_draft.dart';

/// A `PATCH /v1/account/addresses/:addressId` in domain terms: `null` means
/// "unchanged". Built with [AddressUpdate.diff], so an untouched form sends
/// nothing. An empty [floor], [apartment] or [notes] clears that value on the
/// server (the backend allows empty strings only for those three).
class AddressUpdate extends Equatable {
  const AddressUpdate({
    this.label,
    this.location,
    this.city,
    this.block,
    this.street,
    this.building,
    this.floor,
    this.apartment,
    this.phone,
    this.notes,
    this.isDefault,
  });

  /// The fields of [draft] (trimmed) that differ from [original].
  factory AddressUpdate.diff({
    required JameiaAddressEntity original,
    required AddressDraft draft,
  }) {
    String? changed(String current, String edited) {
      final value = edited.trim();
      return value == current ? null : value;
    }

    final samePhone =
        AddressDraft.localPhone(original.phone) ==
        AddressDraft.localPhone(draft.phone);
    // An address saved without a pin opens on the fallback location; leaving
    // it there is not a change.
    final sameLocation =
        draft.location == (original.location ?? AddressDraft.kuwaitCity);
    return AddressUpdate(
      // A custom label from another client reads as `other`: keep it unless
      // the customer picks a different tag.
      label: draft.label == original.labelKind ? null : draft.label,
      location: sameLocation ? null : draft.location,
      city: changed(original.city, draft.city),
      block: changed(original.block, draft.block),
      street: changed(original.street, draft.street),
      building: changed(original.building, draft.building),
      floor: changed(original.floor, draft.floor),
      apartment: changed(original.apartment, draft.apartment),
      phone: samePhone ? null : draft.wirePhone,
      notes: changed(original.notes, draft.notes),
      isDefault: draft.isDefault == original.isDefault ? null : draft.isDefault,
    );
  }

  final AddressLabel? label;
  final GeoPointEntity? location;
  final String? city;
  final String? block;
  final String? street;
  final String? building;
  final String? floor;
  final String? apartment;

  /// Already in wire form (`+965XXXXXXXX`).
  final String? phone;
  final String? notes;
  final bool? isDefault;

  bool get isEmpty => props.every((value) => value == null);

  @override
  List<Object?> get props => [
    label,
    location,
    city,
    block,
    street,
    building,
    floor,
    apartment,
    phone,
    notes,
    isDefault,
  ];
}
