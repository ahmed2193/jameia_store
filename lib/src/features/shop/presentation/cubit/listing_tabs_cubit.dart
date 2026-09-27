import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_listing_category_tabs_usecase.dart';
import 'listing_tabs_state.dart';

/// The category tabs of one collection page (`GET /v1/categories` + one
/// probe per top-level category). Page-scoped. The tabs are a nicety: a
/// failure is only logged and keeps the tabs on screen (none on a first
/// load) — the list works without them. A failed load is tried again when
/// the connection returns.
class ListingTabsCubit extends Cubit<ListingTabsState>
    with SafeCubitMixin<ListingTabsState> {
  ListingTabsCubit(this._getTabs, {required CatalogProductQuery query})
    : _params = GetListingCategoryTabsParams(query: query),
      super(const ListingTabsState());

  static const String _logName = 'shop';

  final GetListingCategoryTabsUseCase _getTabs;
  final GetListingCategoryTabsParams _params;

  /// Bumped by every load; a reply from an older one (the previous language)
  /// is stale.
  int _generation = 0;

  /// First load and language switch. The tabs on screen stay while the new
  /// ones load.
  Future<void> load() async {
    final generation = ++_generation;
    safeEmit(state.copyWith(status: ListingTabsStatus.loading));
    final result = await _getTabs(_params);
    if (generation != _generation) return;
    result.fold(
      (failure) {
        log('category tabs not refreshed', name: _logName, error: failure);
        safeEmit(state.copyWith(status: ListingTabsStatus.failed));
      },
      (categories) => safeEmit(
        ListingTabsState(
          status: ListingTabsStatus.loaded,
          categories: categories,
        ),
      ),
    );
  }

  /// The connection came back: tabs that failed to load are asked again (a
  /// reload running already makes this a no-op).
  Future<void> onReconnected() =>
      state.status == ListingTabsStatus.failed ? load() : Future<void>.value();
}
