import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Drops a line (swipe / trash on the cart page).
class RemoveCartLineUseCase implements SyncUseCase<Unit, RemoveCartLineParams> {
  const RemoveCartLineUseCase(this._repository);
  final CartRepository _repository;

  @override
  Either<Failure, Unit> call(RemoveCartLineParams params) =>
      _repository.removeLine(params.ref);
}

class RemoveCartLineParams extends Equatable {
  const RemoveCartLineParams(this.ref);

  final CartLineRef ref;

  @override
  List<Object?> get props => [ref];
}
