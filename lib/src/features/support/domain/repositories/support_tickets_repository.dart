import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/support_category_entity.dart';
import '../entities/support_ticket_draft.dart';
import '../entities/support_ticket_receipt.dart';

/// Support tickets on the Hero API: the taxonomy of the compose form
/// (public) and opening a ticket (a signed-in customer). The FAQ / hub /
/// chat screens keep their offline `SupportRepository` for now.
abstract class SupportTicketsRepository {
  /// `GET /v1/support/categories`.
  Future<Either<Failure, List<SupportCategoryEntity>>> getCategories();

  /// `POST /v1/support/tickets`.
  Future<Either<Failure, SupportTicketReceipt>> createTicket(
    SupportTicketDraft draft,
  );
}
