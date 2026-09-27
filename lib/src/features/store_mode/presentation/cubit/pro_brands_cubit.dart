import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_pro_brands_usecase.dart';
import 'pro_brands_state.dart';

/// The brands the Pro paywall shows in its logo rows. Secondary information:
/// when they cannot be loaded the page keeps what it had (at first: nothing,
/// so the rows are simply not shown).
class ProBrandsCubit extends Cubit<ProBrandsState>
    with SafeCubitMixin<ProBrandsState> {
  ProBrandsCubit(this._getBrands) : super(const ProBrandsState());

  static const String _logName = 'ProBrandsCubit';

  final GetProBrandsUseCase _getBrands;

  /// Bumped by every [load]; an older reply that lands after a newer one is
  /// dropped.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    final result = await _getBrands(const NoParams());
    if (generation != _generation) return;
    result.fold(
      (failure) => log('brands unavailable', name: _logName, error: failure),
      _show,
    );
  }

  /// The connection came back: ask again when no brand could be shown yet.
  Future<void> onReconnected() =>
      state.brands.isEmpty ? load() : Future<void>.value();

  /// Frozen so no widget can mutate the state. An unchanged reply emits
  /// nothing (Bloc would let a first equal emit through).
  void _show(List<BrandEntity> brands) {
    final next = ProBrandsState(brands: List<BrandEntity>.unmodifiable(brands));
    if (next == state) return;
    safeEmit(next);
  }
}
