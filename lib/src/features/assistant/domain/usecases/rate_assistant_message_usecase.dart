import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_message_entity.dart';
import '../repositories/assistant_repository.dart';

class RateAssistantMessageParams extends Equatable {
  const RateAssistantMessageParams({
    required this.messageId,
    required this.feedback,
  });

  final String messageId;

  /// `none` clears the rating.
  final AssistantFeedback feedback;

  @override
  List<Object?> get props => [messageId, feedback];
}

class RateAssistantMessageUseCase
    implements UseCase<Unit, RateAssistantMessageParams> {
  const RateAssistantMessageUseCase(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RateAssistantMessageParams params) =>
      _repository.rateMessage(
        messageId: params.messageId,
        feedback: params.feedback,
      );
}
