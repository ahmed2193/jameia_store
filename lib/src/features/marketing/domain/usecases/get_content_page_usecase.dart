import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/content_page_entity.dart';
import '../repositories/promotions_repository.dart';

class GetContentPageParams extends Equatable {
  const GetContentPageParams(this.kind);

  final ContentPageKind kind;

  @override
  List<Object?> get props => [kind];
}

/// Loads a CMS page (`GET /v1/pages/:slug`).
class GetContentPageUseCase
    implements UseCase<ContentPageEntity, GetContentPageParams> {
  const GetContentPageUseCase(this._repository);

  final PromotionsRepository _repository;

  @override
  Future<Either<Failure, ContentPageEntity>> call(
    GetContentPageParams params,
  ) => _repository.getContentPage(params.kind);
}
