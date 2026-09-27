import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';

class BrandsState extends Equatable implements ScreenLoadState<BrandsState> {
  const BrandsState({
    this.load = const ScreenLoad(),
    this.brands = const <BrandEntity>[],
  });

  /// The list's read, its freshness (the device copy, a failed refresh …)
  /// and the failure that goes with them.
  @override
  final ScreenLoad load;
  final List<BrandEntity> brands;

  LoadPhase get status => load.phase;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;
  bool get isEmpty => isLoaded && brands.isEmpty;

  @override
  BrandsState withLoad(ScreenLoad load) => copyWith(load: load);

  BrandsState copyWith({ScreenLoad? load, List<BrandEntity>? brands}) =>
      BrandsState(
        load: load ?? this.load.settled(),
        brands: brands ?? this.brands,
      );

  @override
  List<Object?> get props => [load, brands];
}
