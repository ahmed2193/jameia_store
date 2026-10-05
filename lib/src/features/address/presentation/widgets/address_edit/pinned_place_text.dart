import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/utils/address_display.dart';
import '../../../domain/entities/address_draft.dart';
import '../../../domain/entities/pinned_place.dart';

// The lines that name a pin or an address, localized: the name a customer
// knows the spot by comes first ("D. Lamnabha, 36" in Glovo's words). Each
// part reads as in every address line ([addressLinePart]: "Street 12",
// "5 St. 6 Lane", its own direction kept in a right-to-left line [rtl]).

/// The pin's line: a named place, else the street and its number, else the
/// block, else the area; "Pinned location" when nothing is known.
String pinTitle(PinnedPlace place, {bool rtl = false}) {
  if (place.name.isNotEmpty) return addressLineName(place.name, rtl: rtl);
  return _headline(
    street: place.street,
    building: place.building,
    block: place.block,
    area: place.area,
    rtl: rtl,
  );
}

/// The address form's line, from what the customer filled in.
String draftTitle(AddressDraft draft, {bool rtl = false}) => _headline(
  street: draft.street.trim(),
  building: draft.building.trim(),
  block: draft.block.trim(),
  area: draft.city.trim(),
  rtl: rtl,
);

/// The second line of the address form: block (when the first line shows
/// the street), area and country.
String draftSubtitle(AddressDraft draft, {bool rtl = false}) {
  final street = draft.street.trim();
  final block = draft.block.trim();
  final area = draft.city.trim();
  return [
    if (street.isNotEmpty && block.isNotEmpty)
      addressLinePart(AddressLinePart.block, block, rtl: rtl),
    if (area.isNotEmpty && (street.isNotEmpty || block.isNotEmpty))
      addressLineName(area, rtl: rtl),
    'addr.country'.tr(),
  ].join('addr.line.separator'.tr());
}

String _headline({
  required String street,
  required String building,
  required String block,
  required String area,
  required bool rtl,
}) {
  if (street.isNotEmpty) {
    final line = addressLinePart(AddressLinePart.street, street, rtl: rtl);
    if (building.isEmpty) return line;
    final number = addressLinePart(
      AddressLinePart.building,
      building,
      rtl: rtl,
    );
    return '$line${'addr.line.separator'.tr()}$number';
  }
  if (block.isNotEmpty) {
    return addressLinePart(AddressLinePart.block, block, rtl: rtl);
  }
  if (area.isNotEmpty) return addressLineName(area, rtl: rtl);
  return 'addr.pinned_location'.tr();
}
