import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// `POST /v1/cart/coupon`; the code is trimmed and must be 2..32 characters
/// (the API's limits) before any request goes out.
class ApplyCartCouponUseCase implements UseCase<Unit, ApplyCartCouponParams> {
  const ApplyCartCouponUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ApplyCartCouponParams params) {
    final code = params.code.trim();
    if (code.length < CartCouponEntity.minCodeLength ||
        code.length > CartCouponEntity.maxCodeLength) {
      return Future.value(const Left(ValidationFailure('coupon code length')));
    }
    return _repository.applyCoupon(code);
  }
}

class ApplyCartCouponParams extends Equatable {
  const ApplyCartCouponParams(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
