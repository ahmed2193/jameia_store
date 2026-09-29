import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/support_category_entity.dart';
import '../repositories/support_tickets_repository.dart';

/// The support taxonomy (categories, topics, what each must name).
class GetSupportCategoriesUseCase
    implements UseCase<List<SupportCategoryEntity>, NoParams> {
  const GetSupportCategoriesUseCase(this._repository);
  final SupportTicketsRepository _repository;

  @override
  Future<Either<Failure, List<SupportCategoryEntity>>> call(NoParams params) =>
      _repository.getCategories();
}
