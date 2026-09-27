import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared address-domain enums (used by the saved-address model). Kept here so
// HeroGeocode is the single source of truth for the offline LBS contract.
// ─────────────────────────────────────────────────────────────────────────────

/// Hero `structType` — the place ARCHETYPE that drives which form fields show.
/// Separate from [LabelType] (the user-facing tag). KW int codes in the comment.
enum StructType {
  apartment(2),
  house(3),
  office(4);

  const StructType(this.code);

  /// Hero numeric struct code (`regionDefaultStructType=2`).
  final int code;

  static StructType fromCode(int code) => StructType.values.firstWhere(
    (s) => s.code == code,
    orElse: () => StructType.apartment,
  );
}

/// Hero `labelType` — the saved-address TAG glyph (Home/Work/…); distinct from
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

/// Hero `dropOffType`.
enum DropOff { handToMe, leaveAtSpot }

/// Offline LBS emulation — a deterministic, networkless stand-in for Hero's
/// reverse geocode, autocomplete, serviceable-city gate and pin fence. Pure +
/// static so every map screen and address cubit reads ONE source of truth.
class HeroGeocode {
  HeroGeocode._();

  /// Kuwait base coordinate (Kuwait City) — device "current location" + default
  /// map centre.
  static const LatLng base = LatLng(29.3759, 47.9774);

  /// Serviceable bound (pin-pan clamp). SW(28.45,47.50) → NE(30.10,48.45).
  static final LatLngBounds fence = LatLngBounds(
    southwest: const LatLng(28.45, 47.50),
    northeast: const LatLng(30.10, 48.45),
  );

  /// Kuwait-metro service polygon (closed ring, `lng,lat` order in Hero's
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
  /// codes Hero surfaces in its candidate list (e.g. `7WQJ+3M`).
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
}
