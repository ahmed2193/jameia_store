import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_brands_usecase.dart';
import 'brands_state.dart';

/// The store's brands (`GET /v1/brands`).
class BrandsCubit extends Cubit<BrandsState> with SafeCubitMixin<BrandsState> {
  BrandsCubit(this._getBrands) : super(const BrandsState());

  final GetBrandsUseCase _getBrands;
  int _generation = 0;

  Future<void> load() async {
    if (!state.isLoaded) safeEmit(state.copyWith(status: BrandsStatus.loading));
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await _getBrands(const NoParams());
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded ? BrandsStatus.loaded : BrandsStatus.error,
          failure: failure,
        ),
      ),
      (brands) =>
          safeEmit(state.copyWith(status: BrandsStatus.loaded, brands: brands)),
    );
  }
}
