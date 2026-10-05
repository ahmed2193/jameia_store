import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/service_area.dart';

/// Where Hero delivers.
abstract class ServiceAreaRepository {
  Future<Either<Failure, ServiceArea>> serviceArea();
}
