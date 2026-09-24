import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_item_request.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Adds several products ("reorder"): invalid rows are dropped, an empty
/// request is a no-op, and more rows than one request may carry go out in
/// consecutive batches instead of being silently cut off. Stops at the first
/// batch the server refuses.
class AddCartItemsUseCase implements UseCase<Unit, AddCartItemsParams> {
  const AddCartItemsUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AddCartItemsParams params) async {
    final items = [
      for (final item in params.items)
        if (item.isValid) item,
    ];
    if (items.isEmpty) return const Right(unit);
    const batchSize = CartItemRequest.maxItemsPerRequest;
    for (var start = 0; start < items.length; start += batchSize) {
      final end = start + batchSize;
      final result = await _repository.addItems(
        items.sublist(start, end > items.length ? items.length : end),
      );
      if (result.isLeft()) return result;
    }
    return const Right(unit);
  }
}

class AddCartItemsParams extends Equatable {
  const AddCartItemsParams(this.items);

  final List<CartItemRequest> items;

  @override
  List<Object?> get props => [items];
}
