import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/region_options.dart';

/// The serviceable-region picker (offline: hard-coded anchors plus the active
/// region kept by the catalogue).
abstract class ServiceRegionRepository {
  /// The serviceable-region anchors + the currently-active region code.
  Future<Either<Failure, RegionOptions>> getServiceRegions();

  /// Commit a region switch (`switchRegion` + `com.jameia.changed.region`).
  Future<Either<Failure, Unit>> switchRegion(String region);
}
