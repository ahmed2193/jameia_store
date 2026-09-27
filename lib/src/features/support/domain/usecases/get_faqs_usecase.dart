import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/faq_item.dart';
import '../repositories/support_repository.dart';

/// The full FAQ list of the self-serve topics page.
class GetFaqsUseCase implements UseCase<List<FaqItem>, NoParams> {
  const GetFaqsUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, List<FaqItem>>> call(NoParams params) =>
      _repository.getFaqs();
}
