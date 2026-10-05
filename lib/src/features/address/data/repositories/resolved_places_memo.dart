import 'dart:collection';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/pinned_place.dart';

/// The geocoder's answers kept per spot (≈1 m) and language, for as long
/// as the app runs: a pin confirmed again where it was — the picker opened
/// once more, the map back from "Adjust pin" — asks the geocoder nothing.
/// The least recently used answer goes first.
class ResolvedPlacesMemo {
  final LinkedHashMap<String, PinnedPlace> _kept =
      LinkedHashMap<String, PinnedPlace>();

  static const int _capacity = 48;
  static const int _spotDigits = 5;

  /// The answer kept for [point], at [point].
  PinnedPlace? at(GeoPointEntity point, String languageCode) {
    final key = _key(point, languageCode);
    final kept = _kept.remove(key);
    if (kept == null) return null;
    _kept[key] = kept;
    return kept.movedTo(point);
  }

  void keep(GeoPointEntity point, String languageCode, PinnedPlace place) {
    _kept[_key(point, languageCode)] = place;
    if (_kept.length > _capacity) _kept.remove(_kept.keys.first);
  }

  static String _key(GeoPointEntity point, String languageCode) =>
      '${point.lat.toStringAsFixed(_spotDigits)},'
      '${point.lng.toStringAsFixed(_spotDigits)}@$languageCode';
}
