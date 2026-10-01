import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/geo_metric_frame.dart';

/// How fast each stretch of a road service's road may be ridden, looked up
/// by metres along the road: stretch `i` runs from `points[i]` to
/// `points[i + 1]` at `paces[i]` m/s (0 = not said).
class DemoCourierPaces {
  factory DemoCourierPaces(List<GeoPointEntity> points, List<double> paces) {
    if (points.length < 2 || paces.length != points.length - 1) {
      return const DemoCourierPaces._(<double>[], <double>[]);
    }
    final frame = GeoMetricFrame(points.first);
    final ends = <double>[];
    var along = 0.0;
    for (var i = 1; i < points.length; i++) {
      along += frame
          .toMeters(points[i - 1])
          .distanceTo(frame.toMeters(points[i]));
      ends.add(along);
    }
    return DemoCourierPaces._(ends, paces);
  }

  const DemoCourierPaces._(this._ends, this._paces);

  /// Where each stretch ends, in metres along the road.
  final List<double> _ends;
  final List<double> _paces;

  /// The pace of the stretch [meters] along the road; 0 when unknown.
  double at(double meters) {
    if (_ends.isEmpty) return 0;
    var low = 0;
    var high = _ends.length - 1;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_ends[mid] < meters) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return _paces[low];
  }
}
