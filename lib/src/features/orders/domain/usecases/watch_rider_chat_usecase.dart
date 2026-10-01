import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/rider_chat.dart';
import '../repositories/rider_chat_repository.dart';

class WatchRiderChatParams extends Equatable {
  const WatchRiderChatParams(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// The conversation with the rider, live.
class WatchRiderChatUseCase
    implements StreamUseCase<RiderChat, WatchRiderChatParams> {
  const WatchRiderChatUseCase(this._repository);

  final RiderChatRepository _repository;

  @override
  Stream<RiderChat> call(WatchRiderChatParams params) =>
      _repository.watch(params.orderId);
}
