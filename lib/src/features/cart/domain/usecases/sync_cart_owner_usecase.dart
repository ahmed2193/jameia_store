import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Binds the cart to the session owner: the signed-in customer, or the guest
/// (empty id). Fetches the server cart and sends what is still pending.
class SyncCartOwnerUseCase implements UseCase<Unit, SyncCartOwnerParams> {
  const SyncCartOwnerUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SyncCartOwnerParams params) =>
      _repository.syncOwner(
        params.customerId.isEmpty
            ? CartRepository.guestOwnerId
            : params.customerId,
      );
}

class SyncCartOwnerParams extends Equatable {
  const SyncCartOwnerParams({this.customerId = ''});

  /// Empty while signed out.
  final String customerId;

  @override
  List<Object?> get props => [customerId];
}
