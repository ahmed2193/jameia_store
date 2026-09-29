import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/support_ticket_draft.dart';
import '../entities/support_ticket_receipt.dart';
import '../repositories/support_tickets_repository.dart';

/// Opens a ticket; one the API would refuse (no subject or body, or past a
/// limit) never leaves the app.
class CreateSupportTicketUseCase
    implements UseCase<SupportTicketReceipt, CreateSupportTicketParams> {
  const CreateSupportTicketUseCase(this._repository);
  final SupportTicketsRepository _repository;

  @override
  Future<Either<Failure, SupportTicketReceipt>> call(
    CreateSupportTicketParams params,
  ) {
    if (!params.draft.isValid) {
      return Future.value(const Left(ValidationFailure('support ticket')));
    }
    return _repository.createTicket(params.draft);
  }
}

class CreateSupportTicketParams extends Equatable {
  const CreateSupportTicketParams(this.draft);

  final SupportTicketDraft draft;

  @override
  List<Object?> get props => [draft];
}
