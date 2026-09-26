import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';

/// The brands the Pro paywall's logo rows show; empty = no rows.
class ProBrandsState extends Equatable {
  const ProBrandsState({this.brands = const <BrandEntity>[]});

  final List<BrandEntity> brands;

  @override
  List<Object?> get props => [brands];
}
