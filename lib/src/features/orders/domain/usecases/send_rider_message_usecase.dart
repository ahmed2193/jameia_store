import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/rider_quick_reply.dart';
import '../repositories/rider_chat_repository.dart';

class SendRiderMessageParams extends Equatable {
  const SendRiderMessageParams({
    required this.orderId,
    required this.text,
    this.quick,
  });

  final String orderId;
  final String text;
  final RiderQuickReply? quick;

  @override
  List<Object?> get props => [orderId, text, quick];
}

/// Sends a message to the rider: trimmed, never empty, at most [maxLength]
/// characters (a note at the door, not a letter).
class SendRiderMessageUseCase implements UseCase<Unit, SendRiderMessageParams> {
  const SendRiderMessageUseCase(this._repository);

  final RiderChatRepository _repository;

  static const int maxLength = 300;

  @override
  Future<Either<Failure, Unit>> call(SendRiderMessageParams params) async {
    final text = params.text.trim();
    if (text.isEmpty) return const Left(ValidationFailure('empty message'));
    if (text.length > maxLength) {
      return const Left(ValidationFailure('message too long'));
    }
    return _repository.send(params.orderId, text, quick: params.quick);
  }
}
