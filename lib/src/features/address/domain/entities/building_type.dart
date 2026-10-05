import '../../../../core/domain/entities/address_label.dart';
import '../../../../core/domain/entities/hero_address_entity.dart';

/// The kind of building at the pin. It shapes the address form (a house has
/// no floor or flat to ask for) and the words of its fields; the API has no
/// field for it, so an existing address gets it back from what it stores
/// ([BuildingType.of]).
enum BuildingType {
  house,
  apartment,
  office,
  other;

  /// Whether the form asks for a floor and a flat / office number.
  bool get hasUnits => this != house;

  /// The kind an address saved earlier reads as: no floor and no flat is a
  /// house, the Work tag an office, anything else an apartment.
  static BuildingType of(HeroAddressEntity address) {
    final noUnits =
        address.floor.trim().isEmpty && address.apartment.trim().isEmpty;
    if (noUnits) return house;
    return address.labelKind == AddressLabel.work ? office : apartment;
  }
}
