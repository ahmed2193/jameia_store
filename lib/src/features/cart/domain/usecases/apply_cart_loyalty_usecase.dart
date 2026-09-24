import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_loyalty_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// `POST /v1/cart/loyalty { points }` — at least one point.
class ApplyCartLoyaltyUseCase implements UseCase<Unit, ApplyCartLoyaltyParams> {
  const ApplyCartLoyaltyUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ApplyCartLoyaltyParams params) {
    if (params.points < CartLoyaltyEntity.minPoints) {
      return Future.value(const Left(ValidationFailure('loyalty points')));
    }
    return _repository.applyLoyalty(params.points);
  }
}

class ApplyCartLoyaltyParams extends Equatable {
  const ApplyCartLoyaltyParams(this.points);

  final int points;

  @override
  List<Object?> get props => [points];
}
