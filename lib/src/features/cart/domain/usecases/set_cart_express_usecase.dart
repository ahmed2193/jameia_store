import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// `POST /v1/cart/express { enabled }`.
class SetCartExpressUseCase implements UseCase<Unit, SetCartExpressParams> {
  const SetCartExpressUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetCartExpressParams params) =>
      _repository.setExpress(enabled: params.enabled);
}

class SetCartExpressParams extends Equatable {
  const SetCartExpressParams({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
