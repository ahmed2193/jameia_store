import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/category_browse.dart';
import '../../domain/usecases/watch_category_tree_usecase.dart';
import 'category_browse_state.dart';

/// Drives the category rows of a catalogue screen — the store tab's top-level
/// tabs, a category's sub-category rail and its chips — from the one tree the
/// backend sends (`GET /v1/categories`; the device copy first, offline too).
/// The products underneath are a `ProductListingCubit` the page re-scopes to
/// [CategoryBrowse.activeSlug].
///
/// The whole store (`baseSlug` empty) opens on its first category, so a
/// customer who lands on the tab sees products without picking anything.
class CategoryBrowseCubit extends Cubit<CategoryBrowseState>
    with
        SafeCubitMixin<CategoryBrowseState>,
        SnapshotLoaderMixin<CategoryBrowseState>,
        ScreenLoaderMixin<CategoryBrowseState> {
  /// [baseSlug] is the category the screen was opened for; empty browses the
  /// whole store.
  CategoryBrowseCubit(this._watchTree, {String baseSlug = ''})
    : _baseSlug = baseSlug.isEmpty ? null : baseSlug,
      super(
        CategoryBrowseState.initial(
          baseSlug: baseSlug.isEmpty ? null : baseSlug,
        ),
      );

  final WatchCategoryTreeUseCase _watchTree;
  final String? _baseSlug;

  /// First load, retry, language switch. Keeps what is on screen while it
  /// reloads, so a language switch does not blank the rows.
  Future<void> load() {
    showLoading();
    return _read(WatchParams.cached);
  }

  /// Pull-to-refresh: asks the backend again instead of reusing the tree.
  @override
  Future<void> refresh() => _read(WatchParams.fresh);

  /// Pick [category] at [level] (`null` = that level's "All"). Everything
  /// below is dropped — it belonged to the previous pick.
  void select(int level, CatalogCategoryEntity? category) {
    final next = state.browse.select(level, category);
    if (next == state.browse) return;
    safeEmit(state.copyWith(browse: next));
  }

  Future<void> _read(WatchParams params) => readScreen<CatalogCategoryTree>(
    _watchTree(params),
    show: (state, snapshot) => state.copyWith(
      browse: CategoryBrowse.resolve(
        snapshot.data,
        baseSlug: _baseSlug,
        pathSlugs: state.browse.pathSlugs,
        selectFirstOption: _baseSlug == null,
      ),
    ),
  );
}
