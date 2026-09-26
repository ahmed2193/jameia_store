import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_thread.dart';
import '../repositories/assistant_repository.dart';

class GetAssistantConversationParams extends Equatable {
  const GetAssistantConversationParams(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

class GetAssistantConversationUseCase
    implements UseCase<AssistantThread, GetAssistantConversationParams> {
  const GetAssistantConversationUseCase(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, AssistantThread>> call(
    GetAssistantConversationParams params,
  ) => _repository.getConversation(params.conversationId);
}
