import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_availability.dart';
import '../repositories/assistant_repository.dart';

class GetAssistantAvailabilityUseCase
    implements UseCase<AssistantAvailability, NoParams> {
  const GetAssistantAvailabilityUseCase(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, AssistantAvailability>> call(NoParams params) =>
      _repository.getAvailability();
}
