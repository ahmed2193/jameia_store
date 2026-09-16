import 'package:dartz/dartz.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_detail.dart';

/// Builds the full [ProductDetail] aggregate for a tapped [Product]. Offline —
/// the impl assembles it from a dummy/seed data source (backed by the in-memory
/// catalogue for real imagery).
abstract class ProductDetailsRepository {
  Future<Either<Failure, ProductDetail>> getDetails(Product product);
}
