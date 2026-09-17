import 'package:dartz/dartz.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/product_details_repository.dart';
import '../datasources/product_details_dummy_data_source.dart';

class ProductDetailsRepositoryImpl implements ProductDetailsRepository {
  ProductDetailsRepositoryImpl({required this.local});

  final ProductDetailsDummyDataSource local;

  @override
  Future<Either<Failure, ProductDetail>> getDetails(Product product) async {
    try {
      return Right(local.build(product));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
