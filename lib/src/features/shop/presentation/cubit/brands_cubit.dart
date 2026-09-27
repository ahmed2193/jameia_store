import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/usecases/watch_brands_usecase.dart';
import 'brands_state.dart';

/// The store's brands (`GET /v1/brands`): the device copy first (offline
/// too), then the server's; the screen flow is the loader mixins'.
class BrandsCubit extends Cubit<BrandsState>
    with
        SafeCubitMixin<BrandsState>,
        SnapshotLoaderMixin<BrandsState>,
        ScreenLoaderMixin<BrandsState> {
  BrandsCubit(this._watchBrands) : super(const BrandsState());

  final WatchBrandsUseCase _watchBrands;

  /// First load, retry, language switch; the list on screen stays meanwhile.
  Future<void> load() {
    showLoading();
    return _read(WatchParams.cached);
  }

  /// Pull-to-refresh: the server's.
  @override
  Future<void> refresh() => _read(WatchParams.fresh);

  Future<void> _read(WatchParams params) => readScreen<List<BrandEntity>>(
    _watchBrands(params),
    show: (state, snapshot) => state.copyWith(brands: snapshot.data),
  );
}
