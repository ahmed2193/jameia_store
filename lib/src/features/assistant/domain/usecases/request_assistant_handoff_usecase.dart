import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_handoff_ticket.dart';
import '../repositories/assistant_repository.dart';

class RequestAssistantHandoffParams extends Equatable {
  const RequestAssistantHandoffParams(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// "Talk to a person": opens a support ticket for the conversation. The body
/// stays empty — the app never guesses a ticket category.
class RequestAssistantHandoffUseCase
    implements UseCase<AssistantHandoffTicket, RequestAssistantHandoffParams> {
  const RequestAssistantHandoffUseCase(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, AssistantHandoffTicket>> call(
    RequestAssistantHandoffParams params,
  ) => _repository.requestHandoff(params.conversationId);
}
