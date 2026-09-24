import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Locale;

import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import 'jameia_geocode.dart';

/// A fully-resolved place for a pinned [LatLng] — the structured name / city /
/// area / street / house breakdown the address form pre-fills and the candidate
/// list renders. Mirrors Jameia's `poi_detail` / `nearby_address` response.
class ResolvedAddress {
  const ResolvedAddress({
    required this.pos,
    required this.name,
    required this.city,
    required this.area,
    required this.street,
    required this.house,
    required this.building,
    required this.block,
    required this.plusCode,
    required this.title,
    required this.line,
    required this.fromNetwork,
    this.distanceMeters,
  });

  /// The coordinate this place resolves.
  final LatLng pos;

  /// POI / place name (e.g. "The Avenues", a tower, a landmark). May be empty
  /// for a bare street address.
  final String name;

  /// Locality / city (e.g. "Kuwait City", "Salmiya").
  final String city;

  /// District / neighbourhood (sub-locality), Jameia's "area".
  final String area;

  /// Thoroughfare / street name.
  final String street;

  /// Sub-thoroughfare / house or building number.
  final String house;

  /// Named building / place, when distinct from the street.
  final String building;

  /// Block number (KW addressing), parsed when present.
  final String block;

  /// Plus code (Open-Location-Code) for the coordinate.
  final String plusCode;

  /// Short candidate title (the place name, or plus code + area).
  final String title;

  /// Full human address line (street, area, city).
  final String line;

  /// True when resolved by the network (Places/geocoder); false = offline.
  final bool fromNetwork;

  /// Straight-line distance from the query point, when known (nearby search).
  final double? distanceMeters;

  /// Candidate-row shape consumed by the address picker sheet.
  ({String title, String subtitle, LatLng pos}) get asCandidate {
    final dist = distanceMeters == null
        ? ''
        : (distanceMeters! < 1000
              ? ' · ${distanceMeters!.round()} m'
              : ' · ${(distanceMeters! / 1000).toStringAsFixed(1)} km');
    return (title: title, subtitle: '$line$dist', pos: pos);
  }
}

/// Async LBS layer over [JameiaGeocode]. Resolves coordinates to REAL,
/// locale-aware places:
///   • [reverse]  — pin → street address (native geocoder).
///   • [nearby]   — pin → the selected point + its 2 nearest REAL places
///                  (Google Places Nearby Search, ranked by distance).
///   • [search]   — free text → real matching places (Google Places Text Search).
/// Every call is localized to the app locale and falls back gracefully to the
/// deterministic offline data when the network / API is unavailable.
class JameiaLbs {
  JameiaLbs._();

  /// Google Maps Platform key for the HTTP Places endpoints, read from
  /// [AppConstants.mapsApiKey] (injected via `--dart-define=MAPS_API_KEY=...`).
  /// NEVER hardcode it — a web-service key can't be constrained by the Android
  /// app-signature restriction, so a leaked literal is billable by anyone. When
  /// empty the Places calls are skipped and lookups fall back to the native
  /// geocoder + offline [JameiaGeocode].
  static String get _key => AppConstants.mapsApiKey;

  static const _placesBase = 'https://maps.googleapis.com/maps/api/place';

  /// Language code → Places/geocoder `language` param.
  static String _lang(String localeId) =>
      localeId.split(RegExp('[_-]')).first.toLowerCase();

  // ── Reverse geocode (pin → street address) ──────────────────────────────────

  /// Reverse-geocode [p] to a [ResolvedAddress], localized to [localeId]. Tries
  /// the native geocoder first; on any failure returns the offline result.
  static Future<ResolvedAddress> reverse(
    LatLng p, {
    String localeId = 'en',
  }) async {
    final offline = JameiaGeocode.reverse(p);
    try {
      // Built inside the try: with no native geocoder registered (unit tests,
      // unsupported platforms) the constructor throws → offline fallback.
      final placemarks = await geo.Geocoding().placemarkFromCoordinates(
        p.latitude,
        p.longitude,
        locale: Locale(_lang(localeId)),
      );
      if (placemarks.isEmpty) return _fromOffline(p, offline);
      return _fromPlacemark(p, placemarks.first, offline);
    } catch (_) {
      return _fromOffline(p, offline);
    }
  }

  // ── Nearby real places (Places Nearby Search) ───────────────────────────────

  /// The selected point's address + its 2 nearest REAL places (name + address +
  /// distance), ranked by distance. Localized to [localeId]. Falls back to the
  /// offline candidate geometry when Places is unavailable.
  static Future<List<({String title, String subtitle, LatLng pos})>> nearby(
    LatLng p, {
    String localeId = 'en',
    int count = 2,
  }) async {
    final primary = await reverse(p, localeId: localeId);
    final out = <({String title, String subtitle, LatLng pos})>[
      primary.asCandidate,
    ];
    if (_key.isNotEmpty) {
      try {
        final uri = Uri.parse('$_placesBase/nearbysearch/json').replace(
          queryParameters: {
            'location': '${p.latitude},${p.longitude}',
            'rankby': 'distance',
            'type': 'point_of_interest',
            'language': _lang(localeId),
            'key': _key,
          },
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 6));
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == 'OK') {
          final results = (body['results'] as List)
              .cast<Map<String, dynamic>>();
          for (final r in results) {
            if (out.length >= count + 1) break;
            final loc = (r['geometry']?['location']) as Map<String, dynamic>?;
            if (loc == null) continue;
            final pos = LatLng(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
            );
            // Skip the primary point itself (same spot).
            if ((pos.latitude - p.latitude).abs() < 1e-5 &&
                (pos.longitude - p.longitude).abs() < 1e-5) {
              continue;
            }
            final name = (r['name'] as String?)?.trim() ?? '';
            final addr = (r['vicinity'] as String?)?.trim() ?? '';
            out.add((
              title: name.isEmpty ? addr : name,
              subtitle: _withDistance(addr, _haversine(p, pos)),
              pos: pos,
            ));
          }
          if (out.length > 1) return out;
        }
      } catch (_) {
        /* fall through */
      }
    }
    // Offline fallback: pin address + deterministic nearby variations.
    final offsets = JameiaGeocode.nearbyCandidates(p);
    for (final c in offsets.skip(1).take(count)) {
      final r = await reverse(c.pos, localeId: localeId);
      out.add(r.asCandidate);
    }
    return out;
  }

  // ── Search (free text → real places) ────────────────────────────────────────

  /// Free-text place search (Google Places Text Search), biased to the map
  /// centre [near] when given, localized to [localeId]. Falls back to the
  /// offline area table.
  static Future<List<({String title, String subtitle, LatLng pos})>> search(
    String query, {
    String localeId = 'en',
    LatLng? near,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (_key.isNotEmpty) {
      try {
        final params = {
          'query': q,
          'language': _lang(localeId),
          'key': _key,
          if (near != null) 'location': '${near.latitude},${near.longitude}',
          if (near != null) 'radius': '40000',
        };
        final uri = Uri.parse('$_placesBase/textsearch/json')
            .replace(queryParameters: params);
        final res = await http.get(uri).timeout(const Duration(seconds: 6));
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == 'OK') {
          final results = (body['results'] as List)
              .cast<Map<String, dynamic>>();
          final out = <({String title, String subtitle, LatLng pos})>[];
          for (final r in results.take(6)) {
            final loc = (r['geometry']?['location']) as Map<String, dynamic>?;
            if (loc == null) continue;
            final pos = LatLng(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
            );
            out.add((
              title: (r['name'] as String?)?.trim() ?? q,
              subtitle: (r['formatted_address'] as String?)?.trim() ?? '',
              pos: pos,
            ));
          }
          if (out.isNotEmpty) return out;
        }
      } catch (_) {
        /* fall through */
      }
    }
    // Offline fallback: forward geocode then the area table.
    try {
      final locations = await geo.Geocoding().locationFromAddress(
        q,
        locale: Locale(_lang(localeId)),
      );
      final out = <({String title, String subtitle, LatLng pos})>[];
      for (final loc in locations.take(5)) {
        final pos = LatLng(loc.latitude, loc.longitude);
        final r = await reverse(pos, localeId: localeId);
        out.add(r.asCandidate);
      }
      if (out.isNotEmpty) return out;
    } catch (_) {
      /* fall through */
    }
    return JameiaGeocode.autocomplete(q);
  }

  // ── mapping helpers ─────────────────────────────────────────────────────────

  static String _withDistance(String addr, double meters) {
    final d = meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
    return addr.isEmpty ? d : '$addr · $d';
  }

  static ResolvedAddress _fromPlacemark(
    LatLng p,
    geo.Placemark m,
    ({
      String area,
      String line,
      int block,
      int street,
      int house,
      String plusCode,
    })
    offline,
  ) {
    final city = _first([
      m.locality,
      m.subAdministrativeArea,
      m.administrativeArea,
      offline.area,
    ]);
    final area = _first([m.subLocality, m.subAdministrativeArea, city]);
    final street = _first([m.thoroughfare, m.name]);
    final house = _first([m.subThoroughfare]);
    final building =
        (m.name != null &&
            m.name!.isNotEmpty &&
            m.name != street &&
            m.name != house)
        ? m.name!
        : '';
    final titleParts = <String>[
      if (building.isNotEmpty) building else offline.plusCode,
      area,
    ].where((e) => e.isNotEmpty).toList();
    final lineParts = <String>[
      street,
      area,
      city,
    ].where((e) => e.isNotEmpty).toList();
    return ResolvedAddress(
      pos: p,
      name: building,
      city: city,
      area: area,
      street: street,
      house: house,
      building: building,
      block: offline.block.toString(),
      plusCode: offline.plusCode,
      title: titleParts.join(', '),
      line: lineParts.isEmpty ? offline.line : lineParts.join(', '),
      fromNetwork: true,
    );
  }

  static ResolvedAddress _fromOffline(
    LatLng p,
    ({
      String area,
      String line,
      int block,
      int street,
      int house,
      String plusCode,
    })
    offline,
  ) {
    return ResolvedAddress(
      pos: p,
      name: '',
      city: offline.area,
      area: offline.area,
      street: 'Street ${offline.street}',
      house: offline.house.toString(),
      building: '',
      block: offline.block.toString(),
      plusCode: offline.plusCode,
      title: '${offline.plusCode}, ${offline.area}',
      line: offline.line,
      fromNetwork: false,
    );
  }

  static String _first(List<String?> options) {
    for (final o in options) {
      if (o != null && o.trim().isNotEmpty) return o.trim();
    }
    return '';
  }

  /// Straight-line metres between two coordinates (haversine).
  static double _haversine(LatLng a, LatLng b) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h =
        (1 - math.cos(dLat)) / 2 +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            (1 - math.cos(dLng)) /
            2;
    return 2 * r * math.asin(math.sqrt(h));
  }
}
