import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/entities/rider_entity.dart';
import '../../domain/entities/support_hub.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_local_data_source.dart';
import '../mappers/order_mapper.dart';

/// Offline support repository — reads the scripted [SupportLocalDataSource],
/// maps its DTOs to framework-free entities, and wraps the result in
/// `Either<Failure, T>`.
class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl({required this.local});

  final SupportLocalDataSource local;

  @override
  Future<Either<Failure, SupportHub>> getSupportHub() async {
    try {
      final order = local.recentOrder();
      return Right(SupportHub(
        recentOrder: order?.toEntity(),
        faqTopics: local.faqTopics(),
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FaqItem>>> getFaqs() async {
    try {
      return Right(local.faqs());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RiderEntity>> getActiveRider() async {
    try {
      return Right(local.activeRider().toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
