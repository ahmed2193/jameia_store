import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared address-domain enums + value types (used by the address cubits, the
// schema-driven form, and the saved-address model). Kept here so JameiaGeocode is
// the single source of truth for the offline LBS contract.
// ─────────────────────────────────────────────────────────────────────────────

/// Jameia `structType` — the place ARCHETYPE that drives which form fields show.
/// Separate from [LabelType] (the user-facing tag). KW int codes in the comment.
enum StructType {
  apartment(2),
  house(3),
  office(4);

  const StructType(this.code);

  /// Jameia numeric struct code (`regionDefaultStructType=2`).
  final int code;

  static StructType fromCode(int code) => StructType.values.firstWhere(
    (s) => s.code == code,
    orElse: () => StructType.apartment,
  );
}

/// Jameia `labelType` — the saved-address TAG glyph (Home/Work/…); distinct from
/// [StructType]. KW int codes in the comment.
enum LabelType {
  home(0),
  work(1),
  hangout(2),
  faceDelivery(3),
  assignedPlace(4),
  other(5);

  const LabelType(this.code);

  final int code;

  static LabelType fromCode(int code) => LabelType.values.firstWhere(
    (l) => l.code == code,
    orElse: () => LabelType.home,
  );
}

/// Jameia `dropOffType`.
enum DropOff { handToMe, leaveAtSpot }

/// Schema-driven form field keys (the union across all struct types).
enum AddrField {
  area,
  buildingName,
  aptNumber,
  unitOrFloor,
  companyName,
  street,
  block,
  avenue,
  additionalDirection,
  recipient,
  phone,
  note,
}

/// One field's schema (visible + necessary + maxLength) for a struct type.
class AddressFieldSpec {
  const AddressFieldSpec({
    required this.field,
    required this.necessary,
    required this.maxLength,
  });

  final AddrField field;

  /// Required to enable Save.
  final bool necessary;
  final int maxLength;
}

/// Per-structType field set + brief/detail line templates. Mirrors Jameia's
/// `getAllSchemaAndByRegionSwitch` response for KW.
class AddressSchema {
  const AddressSchema(this.fieldsByType);

  /// Ordered, schema-defined field specs for each [StructType].
  final Map<StructType, List<AddressFieldSpec>> fieldsByType;

  List<AddressFieldSpec> fieldsFor(StructType t) =>
      fieldsByType[t] ?? const <AddressFieldSpec>[];

  /// Spec for a single field within a struct type, or null when not shown.
  AddressFieldSpec? specFor(StructType t, AddrField f) {
    for (final s in fieldsFor(t)) {
      if (s.field == f) return s;
    }
    return null;
  }

  /// True when [f] is part of [t]'s field set.
  bool shows(StructType t, AddrField f) => specFor(t, f) != null;

  /// True when [f] is required for [t].
  bool requires(StructType t, AddrField f) => specFor(t, f)?.necessary ?? false;
}

/// Flat struct passed to [JameiaGeocode.composeBrief] / [composeDetail]. The
/// address cubit fills this from its state; the model stores the composed lines.
class AddressStruct {
  const AddressStruct({
    required this.structType,
    this.area = '',
    this.buildingName = '',
    this.aptNumber = '',
    this.unitOrFloor = '',
    this.companyName = '',
    this.street = '',
    this.block = '',
    this.avenue = '',
    this.additionalDirection = '',
  });

  final StructType structType;
  final String area;
  final String buildingName;
  final String aptNumber;
  final String unitOrFloor;
  final String companyName;
  final String street;
  final String block;
  final String avenue;
  final String additionalDirection;
}

/// One serviceable COUNTRY/REGION row for the region picker. Built from the
/// hard-coded anchors (`getOpenServiceRegion`). `anchor` is the city centre.
class ServiceRegionItem {
  const ServiceRegionItem({
    required this.region,
    required this.regionName,
    required this.cityId,
    required this.cityName,
    required this.anchor,
    required this.enabled,
  });

  /// Two-letter region code (HK/SA/AE/QA/KW/BH/BR).
  final String region;

  /// Region/country display name.
  final String regionName;

  /// Jameia numeric city id (as string).
  final String cityId;

  /// City display name (the subtitle).
  final String cityName;

  /// City-centre coordinate (`cityInfo` "lng,lat", parsed to LatLng).
  final LatLng anchor;

  /// Gating flag (BH/BR are feature-flagged off by default).
  final bool enabled;
}

/// Offline LBS emulation — a deterministic, networkless stand-in for Jameia's
/// reverse/forward geocode, autocomplete, serviceable-city gate, pin fence,
/// region list, and order route polyline. Pure + static so every map screen and
/// address cubit reads ONE source of truth.
class JameiaGeocode {
  JameiaGeocode._();

  /// Kuwait base coordinate (Kuwait City) — device "current location" + default
  /// map centre.
  static const LatLng base = LatLng(29.3759, 47.9774);

  /// Serviceable bound (pin-pan clamp). SW(28.45,47.50) → NE(30.10,48.45).
  static final LatLngBounds fence = LatLngBounds(
    southwest: const LatLng(28.45, 47.50),
    northeast: const LatLng(30.10, 48.45),
  );

  /// Kuwait-metro service polygon (closed ring, `lng,lat` order in Jameia's
  /// `fence_cityid_config.json`; stored here as [LatLng]). Used by
  /// [isServiceable] via a real point-in-polygon test.
  static const List<LatLng> _servicePolygon = <LatLng>[
    LatLng(29.4600, 47.6500), // Jahra NW
    LatLng(29.4200, 48.0200), // Sulaibikhat / coast N
    LatLng(29.3900, 48.1100), // Kuwait City waterfront
    LatLng(29.3400, 48.1300), // Salmiya / Ras
    LatLng(29.2600, 48.1300), // Salwa / Bayan coast
    LatLng(29.1000, 48.1700), // Fahaheel / Mangaf coast
    LatLng(29.0500, 48.1500), // Ahmadi south
    LatLng(29.0500, 47.9000), // Ahmadi inland
    LatLng(29.1800, 47.8000), // Sabhan / inland
    LatLng(29.2800, 47.7200), // Farwaniya inland
    LatLng(29.3600, 47.6000), // Jahra approach
    LatLng(29.4600, 47.6500), // close ring
  ];

  /// A handful of real Kuwait areas with approximate centres; the picker snaps
  /// to the nearest one.
  static const List<({String name, double lat, double lng})> areas = [
    (name: 'Kuwait City', lat: 29.3759, lng: 47.9774),
    (name: 'Sharq', lat: 29.3786, lng: 47.9925),
    (name: 'Salmiya', lat: 29.3340, lng: 48.0780),
    (name: 'Hawally', lat: 29.3328, lng: 48.0289),
    (name: 'Jabriya', lat: 29.3225, lng: 48.0214),
    (name: 'Salwa', lat: 29.2917, lng: 48.0772),
    (name: 'Mishref', lat: 29.2742, lng: 48.0583),
    (name: 'Sabah Al Salem', lat: 29.2569, lng: 48.0653),
    (name: 'Farwaniya', lat: 29.2775, lng: 47.9589),
    (name: 'Mahboula', lat: 29.1456, lng: 48.1278),
    (name: 'Mangaf', lat: 29.0972, lng: 48.1336),
    (name: 'Fahaheel', lat: 29.0826, lng: 48.1306),
    (name: 'Jahra', lat: 29.3375, lng: 47.6581),
  ];

  // ── Reverse geocode ─────────────────────────────────────────────────────────

  static ({String name, double lat, double lng}) _nearestArea(LatLng p) {
    var best = areas.first;
    var bestD = double.infinity;
    for (final a in areas) {
      final dLat = a.lat - p.latitude;
      final dLng = a.lng - p.longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestD) {
        bestD = d;
        best = a;
      }
    }
    return best;
  }

  /// Reverse-geocode a coordinate to the nearest area + a deterministic
  /// block/street/house line + plus code. Stands in for `poi_detail`.
  static ({
    String area,
    String line,
    int block,
    int street,
    int house,
    String plusCode,
  })
  reverse(LatLng p) {
    final best = _nearestArea(p);
    final block = 1 + (((p.latitude.abs() * 10000).round()) % 12);
    final street = 1 + (((p.longitude.abs() * 10000).round()) % 80);
    final house = 1 + (((p.latitude.abs() * 100000).round()) % 60);
    return (
      area: best.name,
      line: 'Block $block, Street $street, House $house',
      block: block,
      street: street,
      house: house,
      plusCode: plusCode(p),
    );
  }

  /// A pseudo Open-Location-Code ("plus code") for the coordinate, mirroring the
  /// codes Jameia surfaces in its candidate list (e.g. `7WQJ+3M`).
  static String plusCode(LatLng p) {
    const cs = '23456789CFGHJMPQRVWX';
    String at(double v, double m) => cs[(((v.abs() * m).round()) % 20)];
    return '${at(p.latitude, 20)}${at(p.longitude, 20)}'
        '${at(p.latitude, 400)}${at(p.longitude, 400)}'
        '+${at(p.latitude, 8000)}${at(p.longitude, 8000)}';
  }

  /// One extra plus-code char so candidates 1 and 3 differ slightly.
  static String _csTail(LatLng p) {
    const cs = '23456789CFGHJMPQRVWX';
    return cs[(((p.longitude.abs() * 16000).round()) % 20)];
  }

  // ── Candidate list (nearby_address) ─────────────────────────────────────────

  /// Reverse-geocode to a SHORT-LIST of 3 deterministic candidates, each with
  /// its OWN nearby coordinate so selecting it recenters the map pin. The first
  /// entry is the exact pin position. (Renamed from `candidates()`.)
  static List<({String title, String subtitle, LatLng pos})> nearbyCandidates(
    LatLng p,
  ) {
    final r = reverse(p);
    final plus = r.plusCode;
    final s1 = 1 + (((p.longitude.abs() * 10000).round()) % 80);
    final s2 = 1 + (((p.latitude.abs() * 7000).round()) % 60);
    // ~70–110 m offsets so the pin visibly slides to the chosen POI.
    final p2 = LatLng(p.latitude + 0.00085, p.longitude + 0.00060);
    final p3 = LatLng(p.latitude - 0.00070, p.longitude + 0.00095);
    return [
      (title: '$plus, ${r.area}', subtitle: r.area, pos: p),
      (title: '${r.area}, Street $s1', subtitle: r.line, pos: p2),
      (
        title: '$plus${_csTail(p)}, ${r.area}',
        subtitle: 'Street $s2, ${r.area}',
        pos: p3,
      ),
    ];
  }

  // ── Autocomplete / forward geocode ──────────────────────────────────────────

  /// Search typeahead — filters the area table by name (case-insensitive). Empty
  /// query → []. Stands in for `autocomplete`.
  static List<({String title, String subtitle, LatLng pos})> autocomplete(
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <({String title, String subtitle, LatLng pos})>[];
    for (final a in areas) {
      if (a.name.toLowerCase().contains(q)) {
        final pos = LatLng(a.lat, a.lng);
        out.add((
          title: a.name,
          subtitle: '${plusCode(pos)}, Kuwait',
          pos: pos,
        ));
      }
    }
    return out;
  }

  /// Forward geocode — nearest area whose name matches [query], else [base].
  static LatLng geo(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return base;
    for (final a in areas) {
      if (a.name.toLowerCase().contains(q)) return LatLng(a.lat, a.lng);
    }
    return base;
  }

  // ── Serviceable gate + pin fence ────────────────────────────────────────────

  /// Serviceable-city gate (`getOpenServiceCity`). Real point-in-polygon over
  /// the Kuwait-metro [_servicePolygon] (ray-casting).
  static bool isServiceable(LatLng p) => _pointInPolygon(p, _servicePolygon);

  /// Pin-pan clamp (`isPointInsideRectangle`) over the [fence] rectangle.
  static bool insideFence(LatLng p) =>
      p.latitude >= fence.southwest.latitude &&
      p.latitude <= fence.northeast.latitude &&
      p.longitude >= fence.southwest.longitude &&
      p.longitude <= fence.northeast.longitude;

  /// Ray-casting point-in-polygon. Polygon is a closed ring of [LatLng]
  /// (lng = x, lat = y).
  static bool _pointInPolygon(LatLng p, List<LatLng> poly) {
    var inside = false;
    final x = p.longitude;
    final y = p.latitude;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].longitude, yi = poly[i].latitude;
      final xj = poly[j].longitude, yj = poly[j].latitude;
      final intersect =
          ((yi > y) != (yj > y)) &&
          (x <
              (xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  // ── Region picker (getOpenServiceRegion) ────────────────────────────────────

  /// The 7 hard-coded serviceable anchors. BH/BR gated by [enableBH]/[enableBR].
  static List<ServiceRegionItem> openServiceRegions({
    bool enableBH = true,
    bool enableBR = true,
  }) {
    final list = <ServiceRegionItem>[
      const ServiceRegionItem(
        region: 'HK',
        regionName: 'Hong Kong, China',
        cityId: '810001',
        cityName: 'Hong Kong',
        anchor: LatLng(22.3203648, 114.169773),
        enabled: true,
      ),
      const ServiceRegionItem(
        region: 'SA',
        regionName: 'Saudi Arabia',
        cityId: '1150000081',
        cityName: 'Riyadh',
        anchor: LatLng(24.638916, 46.7160104),
        enabled: true,
      ),
      const ServiceRegionItem(
        region: 'AE',
        regionName: 'United Arab Emirates',
        cityId: '1010000001',
        cityName: 'Dubai',
        anchor: LatLng(25.073275, 55.245006),
        enabled: true,
      ),
      const ServiceRegionItem(
        region: 'QA',
        regionName: 'Qatar',
        cityId: '114000008',
        cityName: 'Doha',
        anchor: LatLng(25.274983, 51.531562),
        enabled: true,
      ),
      const ServiceRegionItem(
        region: 'KW',
        regionName: 'Kuwait',
        cityId: '109100007',
        cityName: 'Kuwait City',
        anchor: LatLng(29.377711, 47.975956),
        enabled: true,
      ),
      ServiceRegionItem(
        region: 'BH',
        regionName: 'Bahrain',
        cityId: '101200005',
        cityName: 'Manama',
        anchor: const LatLng(26.239651, 50.581259),
        enabled: enableBH,
      ),
      ServiceRegionItem(
        region: 'BR',
        regionName: 'Brazil',
        cityId: '102306232',
        cityName: 'São Paulo',
        anchor: const LatLng(-23.5489841, -46.6332165),
        enabled: enableBR,
      ),
    ];
    return list;
  }

  // ── Order route polyline + ETA ──────────────────────────────────────────────

  /// Ordered route shop → rider → user with a couple of intermediate bends so
  /// the drawn polyline reads as a road path, not a straight line.
  static List<LatLng> routePolyline(LatLng shop, LatLng rider, LatLng user) {
    LatLng bend(LatLng a, LatLng b, double t, double jitter) {
      final lat = a.latitude + (b.latitude - a.latitude) * t;
      final lng = a.longitude + (b.longitude - a.longitude) * t;
      // Perpendicular nudge for an L-ish bend.
      return LatLng(lat + jitter, lng - jitter);
    }

    return <LatLng>[
      shop,
      bend(shop, rider, 0.5, 0.0008),
      rider,
      bend(rider, user, 0.45, -0.0006),
      bend(rider, user, 0.8, 0.0004),
      user,
    ];
  }

  /// Crude ETA in minutes from straight-line distance (km) at ~22 km/h, min 3.
  static int eta(LatLng from, LatLng to) {
    final km = _haversineKm(from, to);
    return math.max(3, (km / 22 * 60).round());
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  // ── KW schema + brief/detail composition ────────────────────────────────────

  /// KW field schema (`getAllSchemaAndByRegionSwitch`). Per-struct visible +
  /// necessary(*) + maxLength. Brief/detail templates live in [composeBrief] /
  /// [composeDetail].
  static const AddressSchema kwSchema = AddressSchema({
    StructType.apartment: <AddressFieldSpec>[
      AddressFieldSpec(field: AddrField.area, necessary: true, maxLength: 100),
      AddressFieldSpec(
        field: AddrField.buildingName,
        necessary: true,
        maxLength: 100,
      ),
      AddressFieldSpec(
        field: AddrField.aptNumber,
        necessary: true,
        maxLength: 50,
      ),
      AddressFieldSpec(
        field: AddrField.unitOrFloor,
        necessary: true,
        maxLength: 50,
      ),
      AddressFieldSpec(
        field: AddrField.street,
        necessary: true,
        maxLength: 100,
      ),
      AddressFieldSpec(field: AddrField.block, necessary: true, maxLength: 50),
      AddressFieldSpec(
        field: AddrField.avenue,
        necessary: false,
        maxLength: 50,
      ),
      AddressFieldSpec(
        field: AddrField.additionalDirection,
        necessary: false,
        maxLength: 100,
      ),
    ],
    StructType.house: <AddressFieldSpec>[
      AddressFieldSpec(field: AddrField.area, necessary: true, maxLength: 100),
      AddressFieldSpec(
        field: AddrField.buildingName,
        necessary: true,
        maxLength: 100,
      ),
      AddressFieldSpec(
        field: AddrField.street,
        necessary: true,
        maxLength: 100,
      ),
      AddressFieldSpec(field: AddrField.block, necessary: true, maxLength: 50),
      AddressFieldSpec(
        field: AddrField.avenue,
        necessary: false,
        maxLength: 50,
      ),
      AddressFieldSpec(
        field: AddrField.additionalDirection,
        necessary: false,
        maxLength: 100,
      ),
    ],
    StructType.office: <AddressFieldSpec>[
      AddressFieldSpec(field: AddrField.area, necessary: true, maxLength: 100),
      AddressFieldSpec(
        field: AddrField.buildingName,
        necessary: true,
        maxLength: 100,
      ),
      AddressFieldSpec(
        field: AddrField.companyName,
        necessary: true,
        maxLength: 50,
      ),
      AddressFieldSpec(
        field: AddrField.unitOrFloor,
        necessary: true,
        maxLength: 50,
      ),
      AddressFieldSpec(
        field: AddrField.street,
        necessary: true,
        maxLength: 100,
      ),
      AddressFieldSpec(field: AddrField.block, necessary: true, maxLength: 50),
      AddressFieldSpec(
        field: AddrField.avenue,
        necessary: false,
        maxLength: 50,
      ),
      AddressFieldSpec(
        field: AddrField.additionalDirection,
        necessary: false,
        maxLength: 100,
      ),
    ],
  });

  /// Brief saved-address line = `{area}, {block}, {street}, {avenue},
  /// {buildingName}` (empty parts dropped).
  static String composeBrief(AddressStruct s) {
    final parts = <String>[
      s.area,
      s.block.isEmpty ? '' : 'Block ${s.block}',
      s.street.isEmpty ? '' : 'Street ${s.street}',
      s.avenue.isEmpty ? '' : 'Avenue ${s.avenue}',
      s.buildingName,
    ];
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
  }

  /// Detail line = `{unitOrFloor}, {aptNumber|companyName}` (empty parts
  /// dropped). Office uses companyName; others use aptNumber.
  static String composeDetail(AddressStruct s) {
    final second = s.structType == StructType.office
        ? s.companyName
        : s.aptNumber;
    final parts = <String>[s.unitOrFloor, second];
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
  }
}
