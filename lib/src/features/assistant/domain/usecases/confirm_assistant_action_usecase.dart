import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_action_result.dart';
import '../repositories/assistant_repository.dart';

class ConfirmAssistantActionParams extends Equatable {
  const ConfirmAssistantActionParams(this.actionId);

  final String actionId;

  @override
  List<Object?> get props => [actionId];
}

/// Applies a cart proposal of the assistant. The server changes the cart
/// itself — the app never replays the proposal through `/v1/cart`.
class ConfirmAssistantActionUseCase
    implements UseCase<AssistantActionResult, ConfirmAssistantActionParams> {
  const ConfirmAssistantActionUseCase(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, AssistantActionResult>> call(
    ConfirmAssistantActionParams params,
  ) => _repository.confirmAction(params.actionId);
}
