import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_update.dart';
import '../models/address_model.dart';

/// `AddressDraft` → the `POST /v1/account/addresses` body. The required keys
/// (`label`, `lat`, `lng`, `city`) always go out; an optional one only when it
/// holds text, because the backend rejects an empty `block` / `street` /
/// `building` / `phone`.
extension AddressDraftBodyMapper on AddressDraft {
  Map<String, Object?> toBody() {
    String? filled(String value) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    return <String, Object?>{
      AddressModel.labelKey: label.wireValue,
      AddressModel.latKey: location.lat,
      AddressModel.lngKey: location.lng,
      AddressModel.cityKey: city.trim(),
      AddressModel.blockKey: ?filled(block),
      AddressModel.streetKey: ?filled(street),
      AddressModel.buildingKey: ?filled(building),
      AddressModel.floorKey: ?filled(floor),
      AddressModel.apartmentKey: ?filled(apartment),
      if (phone.trim().isNotEmpty) AddressModel.phoneKey: wirePhone,
      AddressModel.notesKey: ?filled(notes),
      AddressModel.isDefaultKey: isDefault,
    };
  }
}

/// `AddressUpdate` → the `PATCH /v1/account/addresses/:addressId` body: only
/// the changed keys; a moved pin sends `lat` and `lng` together.
extension AddressUpdateBodyMapper on AddressUpdate {
  Map<String, Object?> toBody() {
    final pin = location;
    return <String, Object?>{
      AddressModel.labelKey: ?label?.wireValue,
      if (pin != null) ...<String, Object?>{
        AddressModel.latKey: pin.lat,
        AddressModel.lngKey: pin.lng,
      },
      AddressModel.cityKey: ?city,
      AddressModel.blockKey: ?block,
      AddressModel.streetKey: ?street,
      AddressModel.buildingKey: ?building,
      AddressModel.floorKey: ?floor,
      AddressModel.apartmentKey: ?apartment,
      AddressModel.phoneKey: ?phone,
      AddressModel.notesKey: ?notes,
      AddressModel.isDefaultKey: ?isDefault,
    };
  }
}
