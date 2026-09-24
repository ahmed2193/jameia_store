import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// `DELETE /v1/cart/coupon`.
class RemoveCartCouponUseCase implements UseCase<Unit, NoParams> {
  const RemoveCartCouponUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.removeCoupon();
}
