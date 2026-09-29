import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/support_category_entity.dart';
import '../../domain/entities/support_ticket_draft.dart';
import '../../domain/entities/support_ticket_receipt.dart';
import '../../domain/repositories/support_tickets_repository.dart';
import '../datasources/support_remote_data_source.dart';
import '../mappers/support_tickets_mapper.dart';

class SupportTicketsRepositoryImpl
    with BaseRepositoryMixin
    implements SupportTicketsRepository {
  const SupportTicketsRepositoryImpl(this._remote);

  final SupportRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<SupportCategoryEntity>>> getCategories() =>
      execute(() async => (await _remote.getCategories()).toEntities());

  @override
  Future<Either<Failure, SupportTicketReceipt>> createTicket(
    SupportTicketDraft draft,
  ) => execute(
    () async => (await _remote.createTicket(draft.toBody())).toEntity(),
  );
}
