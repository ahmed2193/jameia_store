import 'dart:ui';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../../core/widgets/hero_map.dart';
import '../../../domain/entities/courier_stage.dart';
import '../../../domain/entities/courier_trip.dart';
import 'live_map_camera.dart';
import 'live_map_marker_icons.dart';

/// What the live map draws, from the ride and where the rider shows:
///
/// * the store and home pins (built once: they never change, so the map is
///   never sent them again), and the rider turned with the road;
/// * the road still to drive — dashed while it is only planned (with the
///   rider's own way to the store in ink), solid brand green on a white
///   casing once the order is on its way;
/// * the road the rider has already driven, from the store to them: the
///   same road greyed out (disabled grey on the same white casing), laid
///   under the road ahead so the two meet exactly at the rider and the
///   green always reads as what is left (the whole ride grey at the door).
///   Once the order is on its way the grey is the WHOLE ride, built once:
///   the road ahead covers it from the rider on, so the picture is the same
///   and the map is never sent the grey again;
/// * the fading rings of a moment (a rider being found, the door reached).
///
/// Lines are drawn through the road's drawn corners (`drawSlice`): the same
/// ends, without the corners nobody could see.
class LiveMapOverlays {
  LiveMapOverlays({required this.trip, required this.icons});

  final CourierTrip trip;
  final LiveMapMarkerIcons icons;

  late final Marker _store = _pin(
    _storeId,
    trip.store,
    icons.store,
    icons.storeAnchor,
    _storeLayer,
  );
  late final Marker _home = _pin(
    _homeId,
    trip.home,
    icons.home,
    LiveMapMarkerIcons.pinTip,
    _homeLayer,
  );

  /// The whole ride, as the map draws it.
  late final List<LatLng> _wholePath = _points(trip.path.drawPoints);

  /// The whole ride greyed out on its casing: the road driven once the
  /// order is on its way (the road ahead lies over the rest of it).
  late final Set<Polyline> _wholeTravelled = {
    _line(
      _travelledCasingId,
      _wholePath,
      AppColors.white,
      _casingWidth,
      _travelledCasingLayer,
    ),
    _line(
      _travelledId,
      _wholePath,
      AppColors.disabledText,
      _roadWidth,
      _travelledLayer,
    ),
  };

  static const MarkerId _storeId = MarkerId('store');
  static const MarkerId _homeId = MarkerId('home');
  static const MarkerId _riderId = MarkerId('rider');
  static const PolylineId _plannedId = PolylineId('planned');
  static const PolylineId _approachId = PolylineId('approach');
  static const PolylineId _casingId = PolylineId('casing');
  static const PolylineId _roadId = PolylineId('road');
  static const PolylineId _travelledId = PolylineId('travelled');
  static const PolylineId _travelledCasingId = PolylineId('travelled_casing');

  // Stacking: pins, then home over the store, the rider on top.
  static const int _storeLayer = 1;
  static const int _homeLayer = 2;
  static const int _riderLayer = 3;
  // The road driven lies under the road ahead.
  static const int _travelledCasingLayer = 1;
  static const int _travelledLayer = 2;
  static const int _casingLayer = 3;
  static const int _lineLayer = 4;

  static const int _roadWidth = 6;
  static const int _casingWidth = 10;
  static const int _approachWidth = 4;
  static const double _dash = 24;
  static const double _gap = 16;
  static final List<PatternItem> _dashed = [
    PatternItem.dash(_dash),
    PatternItem.gap(_gap),
  ];

  // Rings: metres from the centre as one grows and fades, and how strong
  // a ring is when it starts.
  static const double _ringFrom = 20;
  static const double _ringTo = 110;
  static const double _ringOpacity = 0.35;
  static const int _rings = 2;

  Set<Marker> markers({
    required double riderMeters,
    required CourierStage stage,
    required double riderAlpha,
  }) => {
    _store,
    _home,
    if (stage.hasRider && riderAlpha > 0)
      Marker(
        markerId: _riderId,
        position: LiveMapCamera.latLng(trip.path.pointAt(riderMeters)),
        icon: icons.rider,
        anchor: LiveMapMarkerIcons.riderAnchor,
        rotation: trip.path.headingAround(riderMeters),
        flat: true,
        alpha: riderAlpha,
        consumeTapEvents: true,
        zIndexInt: _riderLayer,
      ),
  };

  /// The road for a rider [lineMeters] down the path at [stage]; [drawn] is
  /// the share of the planned road drawn in so far (the entrance).
  Set<Polyline> polylines({
    required double lineMeters,
    required CourierStage stage,
    required double drawn,
  }) {
    final store = trip.deliveryStartMeters;
    final door = trip.path.lengthMeters;
    if (stage.delivering) {
      if (stage == CourierStage.arrived) return _wholeTravelled;
      final left = _points(trip.path.drawSlice(lineMeters, door));
      return {
        ..._wholeTravelled,
        _line(_casingId, left, AppColors.white, _casingWidth, _casingLayer),
        _line(_roadId, left, AppColors.primary, _roadWidth, _lineLayer),
      };
    }
    final planned = trip.path.drawSlice(store, store + (door - store) * drawn);
    return {
      ..._travelled(stage.hasRider ? lineMeters : 0),
      _line(
        _plannedId,
        _points(planned),
        AppColors.primary,
        _roadWidth,
        _lineLayer,
        dashed: true,
      ),
      if (stage == CourierStage.toStore)
        _line(
          _approachId,
          _points(trip.path.drawSlice(lineMeters, store)),
          AppColors.stickerOutline,
          _approachWidth,
          _lineLayer,
          dashed: true,
        ),
    };
  }

  /// The road driven so far ([meters] from the start) before the order is
  /// on its way, greyed out; none before the rider has moved.
  Set<Polyline> _travelled(double meters) {
    if (meters <= 0) return const <Polyline>{};
    final driven = _points(trip.path.drawSlice(0, meters));
    return {
      _line(
        _travelledCasingId,
        driven,
        AppColors.white,
        _casingWidth,
        _travelledCasingLayer,
      ),
      _line(
        _travelledId,
        driven,
        AppColors.disabledText,
        _roadWidth,
        _travelledLayer,
      ),
    };
  }

  /// Rings spreading from [center] in [color], [lapsDone] of the moment's
  /// [laps] laps done. Each ring is born small and strong, the next one
  /// half a lap later, and the last lap only lets the rings fade out: none
  /// pops in half-grown, none is cut off mid-growth, none is left once all
  /// [laps] are done.
  Set<Circle> rings(
    GeoPointEntity center,
    Color color, {
    required double lapsDone,
    required int laps,
  }) => {
    for (var i = 0; i < _rings; i++)
      if (_ringPhase(lapsDone - i / _rings, laps) case final phase?)
        _ring(CircleId('ring$i'), center, color, phase),
  };

  /// How many laps [rings] draws anything for, of a moment of [laps] laps:
  /// the last ring is born `(rings - 1) / rings` of a lap late and gone
  /// `laps - 1` laps after that. A run this long ends with the last ring.
  static double ringRunLaps(int laps) => laps - 1 + (_rings - 1) / _rings;

  /// How far a ring [sinceBirth] laps old is into its lap (0 → 1); `null`
  /// before it is born and from the moment's last lap on.
  static double? _ringPhase(double sinceBirth, int laps) =>
      sinceBirth >= 0 && sinceBirth < laps - 1 ? sinceBirth % 1 : null;

  /// One ring [phase] (0 → 1) through its growth: wider and fainter.
  static Circle _ring(
    CircleId id,
    GeoPointEntity center,
    Color color,
    double phase,
  ) => Circle(
    circleId: id,
    center: LiveMapCamera.latLng(center),
    radius: _ringFrom + (_ringTo - _ringFrom) * phase,
    fillColor: color.withValues(alpha: _ringOpacity * (1 - phase)),
    strokeWidth: 0,
  );

  static Marker _pin(
    MarkerId id,
    GeoPointEntity at,
    BitmapDescriptor icon,
    Offset anchor,
    int layer,
  ) => Marker(
    markerId: id,
    position: LiveMapCamera.latLng(at),
    icon: icon,
    anchor: anchor,
    consumeTapEvents: true,
    zIndexInt: layer,
  );

  static Polyline _line(
    PolylineId id,
    List<LatLng> points,
    Color color,
    int width,
    int layer, {
    bool dashed = false,
  }) => Polyline(
    polylineId: id,
    points: points,
    color: color,
    width: width,
    zIndex: layer,
    patterns: dashed ? _dashed : const <PatternItem>[],
    jointType: JointType.round,
    startCap: Cap.roundCap,
    endCap: Cap.roundCap,
  );

  static List<LatLng> _points(List<GeoPointEntity> points) => [
    for (final point in points) LiveMapCamera.latLng(point),
  ];
}
