import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_listing_category_tabs_usecase.dart';
import 'listing_tabs_state.dart';

/// The category tabs of one collection page (`GET /v1/categories` + one
/// probe per top-level category). Page-scoped. The tabs are a nicety: a
/// failure hides them and is only logged — the list works without them.
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
        log('category tabs hidden', name: _logName, error: failure);
        safeEmit(const ListingTabsState(status: ListingTabsStatus.failed));
      },
      (categories) => safeEmit(
        ListingTabsState(
          status: ListingTabsStatus.loaded,
          categories: categories,
        ),
      ),
    );
  }
}
