import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/error/failures.dart';

enum BrandsStatus { initial, loading, loaded, error }

class BrandsState extends Equatable {
  const BrandsState({
    this.status = BrandsStatus.initial,
    this.brands = const <BrandEntity>[],
    this.failure,
  });

  final BrandsStatus status;
  final List<BrandEntity> brands;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == BrandsStatus.loaded;
  bool get isEmpty => isLoaded && brands.isEmpty;

  BrandsState copyWith({
    BrandsStatus? status,
    List<BrandEntity>? brands,
    Failure? failure,
  }) => BrandsState(
    status: status ?? this.status,
    brands: brands ?? this.brands,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, brands, failure];
}
