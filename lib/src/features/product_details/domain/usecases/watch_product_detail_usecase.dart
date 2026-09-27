import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_detail.dart';
import '../repositories/product_details_repository.dart';

class WatchProductDetailParams extends Equatable {
  const WatchProductDetailParams(this.slug, {this.forceRefresh = false});

  final String slug;

  /// The page asks the server again (reconnect): skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [slug, forceRefresh];
}

/// A product page (`GET /v1/products/:slug`): the copy saved on the device
/// first, then the server's; failures on the error channel.
class WatchProductDetailUseCase
    implements
        StreamUseCase<DataSnapshot<ProductDetail>, WatchProductDetailParams> {
  const WatchProductDetailUseCase(this._repository);

  final ProductDetailsRepository _repository;

  @override
  Stream<DataSnapshot<ProductDetail>> call(WatchProductDetailParams params) =>
      _repository.watchProduct(params.slug, forceRefresh: params.forceRefresh);
}
