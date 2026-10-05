import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/utils/address_display.dart';
import '../../../domain/entities/place_suggestion.dart';

/// The grey line under an answer of the address search, Google Maps style:
/// where the place is. Google's own line as it came; else the street, the
/// block and the area the map reads at a spot the geocoder found, or a
/// district's governorate — ending in the country. Each part reads as in
/// every address line ([addressLinePart]), its own direction kept in a
/// right-to-left line [rtl].
String suggestionLine(PlaceSuggestion suggestion, {bool rtl = false}) {
  if (suggestion.source == PlaceSource.google) return suggestion.subtitle;
  final place = suggestion.place;
  final street = place?.street ?? '';
  final block = place?.block ?? '';
  final area = place?.area ?? '';
  final region = suggestion.subtitle;
  return [
    if (street.isNotEmpty && street != suggestion.title)
      addressLinePart(AddressLinePart.street, street, rtl: rtl),
    if (block.isNotEmpty)
      addressLinePart(AddressLinePart.block, block, rtl: rtl),
    if (area.isNotEmpty && area != suggestion.title)
      addressLineName(area, rtl: rtl),
    if (region.isNotEmpty) addressLineName(region, rtl: rtl),
    'addr.country'.tr(),
  ].join('addr.line.separator'.tr());
}
