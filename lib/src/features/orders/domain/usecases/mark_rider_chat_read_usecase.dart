import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/rider_chat_repository.dart';

class MarkRiderChatReadParams extends Equatable {
  const MarkRiderChatReadParams(this.orderId, this.at);

  final String orderId;

  /// When the last message the customer has seen was sent.
  final DateTime at;

  @override
  List<Object?> get props => [orderId, at];
}

/// Keeps with the conversation how far the customer has read it, so a map
/// opened again counts (and announces) only the rider's newer messages.
class MarkRiderChatReadUseCase
    implements UseCase<Unit, MarkRiderChatReadParams> {
  const MarkRiderChatReadUseCase(this._repository);

  final RiderChatRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MarkRiderChatReadParams params) =>
      _repository.markRead(params.orderId, params.at);
}
