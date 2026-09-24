import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_review_request.dart';
import '../repositories/orders_repository.dart';

/// `POST /v1/reviews` for one product of a delivered order.
class SubmitProductReviewUseCase
    implements UseCase<Unit, SubmitProductReviewParams> {
  const SubmitProductReviewUseCase(this._repository);
  final OrdersRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SubmitProductReviewParams params) {
    if (!params.request.isValid) {
      return Future.value(const Left(ValidationFailure('review request')));
    }
    return _repository.submitReview(params.request);
  }
}

class SubmitProductReviewParams extends Equatable {
  const SubmitProductReviewParams(this.request);

  final ProductReviewRequest request;

  @override
  List<Object?> get props => [request];
}
