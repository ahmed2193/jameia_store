import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/entities/support_hub.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_local_data_source.dart';
import '../mappers/support_mapper.dart';

/// Offline support repository over the scripted [SupportLocalDataSource].
class SupportRepositoryImpl
    with BaseRepositoryMixin
    implements SupportRepository {
  const SupportRepositoryImpl(this._local);

  final SupportLocalDataSource _local;

  @override
  Future<Either<Failure, SupportHub>> getSupportHub() => execute(
    () async => SupportHub(
      recentOrder: _local.recentOrder()?.toSupportOrder(),
      faqTopics: [
        for (final faq in _local.faqs().take(SupportHub.topicCount))
          faq.toEntity(),
      ],
    ),
  );

  @override
  Future<Either<Failure, List<FaqItem>>> getFaqs() =>
      execute(() async => [for (final faq in _local.faqs()) faq.toEntity()]);

  @override
  Future<Either<Failure, String?>> getActiveRiderName() =>
      execute(() async => _local.activeRiderName());
}
