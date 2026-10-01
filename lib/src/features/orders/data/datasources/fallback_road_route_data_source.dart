import 'dart:developer';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../models/road_route_model.dart';
import 'road_route_data_source.dart';

/// Asks each road service in turn — Google first when the app has a key,
/// then OpenStreetMap roads — and takes the first answer; one that takes
/// longer than [budget] counts as failed and its request is aborted (the
/// budget is passed down, so the losing call never keeps its socket or
/// downloads its late body); when every one fails, the last failure is thrown.
class FallbackRoadRouteDataSource implements RoadRouteDataSource {
  const FallbackRoadRouteDataSource(
    this._sources, {
    this.budget = AppConstants.roadRouteBudget,
  });

  final List<RoadRouteDataSource> _sources;
  final Duration budget;

  static const String _logName = 'courier';

  @override
  Future<RoadRouteModel> route(
    List<GeoPointEntity> stops, {
    Duration? timeout,
  }) async {
    // Each service gets the budget, or the caller's deadline when tighter.
    final limit = timeout != null && timeout < budget ? timeout : budget;
    AppException? last;
    for (final source in _sources) {
      try {
        // The outer timeout guards a service that does not honour its own.
        return await source
            .route(stops, timeout: limit)
            .timeout(
              limit,
              onTimeout: () => throw const RequestTimeoutException(),
            );
      } on AppException catch (error) {
        log('${source.runtimeType} failed: $error', name: _logName);
        last = error;
      }
    }
    throw last ?? const ServerException('no road service');
  }
}
