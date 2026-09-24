import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/search_repository.dart';

class SuggestProductsParams extends Equatable {
  const SuggestProductsParams(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The first product matches for what the customer has typed so far
/// (`GET /v1/products?search=`). Text shorter than [minLength] asks nothing:
/// it would match half the catalogue and costs a request per keystroke.
class SuggestProductsUseCase
    implements UseCase<List<CatalogProductEntity>, SuggestProductsParams> {
  const SuggestProductsUseCase(this._repository);

  static const int minLength = 2;
  static const int maxSuggestions = 6;

  final SearchRepository _repository;

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> call(
    SuggestProductsParams params,
  ) async {
    final text = params.text.trim();
    if (text.length < minLength) {
      return const Right(<CatalogProductEntity>[]);
    }
    return _repository.suggestProducts(text: text, limit: maxSuggestions);
  }
}
