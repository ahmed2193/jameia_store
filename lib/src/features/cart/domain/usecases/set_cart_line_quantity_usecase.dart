import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Absolute quantity for a line the cart shows; `0` removes it.
class SetCartLineQuantityUseCase
    implements SyncUseCase<Unit, SetCartLineQuantityParams> {
  const SetCartLineQuantityUseCase(this._repository);
  final CartRepository _repository;

  @override
  Either<Failure, Unit> call(SetCartLineQuantityParams params) => _repository
      .setLineQuantity(params.ref, params.quantity < 0 ? 0 : params.quantity);
}

class SetCartLineQuantityParams extends Equatable {
  const SetCartLineQuantityParams({required this.ref, required this.quantity});

  final CartLineRef ref;
  final int quantity;

  @override
  List<Object?> get props => [ref, quantity];
}
