import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/category_browse.dart';
import '../../domain/usecases/get_category_tree_usecase.dart';
import 'category_browse_state.dart';

/// Drives the category rows of a catalogue screen — the store tab's top-level
/// tabs, a category's sub-category rail and its chips — from the one tree the
/// backend sends (`GET /v1/categories`). The products underneath are a
/// `ProductListingCubit` the page re-scopes to [CategoryBrowse.activeSlug].
///
/// The whole store (`baseSlug` empty) opens on its first category, so a
/// customer who lands on the tab sees products without picking anything.
class CategoryBrowseCubit extends Cubit<CategoryBrowseState>
    with SafeCubitMixin<CategoryBrowseState> {
  /// [baseSlug] is the category the screen was opened for; empty browses the
  /// whole store.
  CategoryBrowseCubit(this._getCategoryTree, {String baseSlug = ''})
    : _baseSlug = baseSlug.isEmpty ? null : baseSlug,
      super(
        CategoryBrowseState.initial(
          baseSlug: baseSlug.isEmpty ? null : baseSlug,
        ),
      );

  final GetCategoryTreeUseCase _getCategoryTree;
  final String? _baseSlug;

  /// A reply from an older load (a language switch, a retry) is stale.
  int _generation = 0;

  /// First load, retry, language switch. Keeps what is on screen while it
  /// reloads, so a language switch does not blank the rows.
  Future<void> load() async {
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: CategoryBrowseStatus.loading));
    }
    await _fetch(refresh: false);
  }

  /// Pull-to-refresh: asks the backend again instead of reusing the tree.
  Future<void> refresh() => _fetch(refresh: true);

  /// Pick [category] at [level] (`null` = that level's "All"). Everything
  /// below is dropped — it belonged to the previous pick.
  void select(int level, CatalogCategoryEntity? category) {
    final next = state.browse.select(level, category);
    if (next == state.browse) return;
    safeEmit(state.copyWith(browse: next));
  }

  Future<void> _fetch({required bool refresh}) async {
    final generation = ++_generation;
    final result = await _getCategoryTree(
      GetCategoryTreeParams(refresh: refresh),
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? CategoryBrowseStatus.loaded
              : CategoryBrowseStatus.error,
          failure: failure,
        ),
      ),
      (tree) => safeEmit(
        state.copyWith(
          status: CategoryBrowseStatus.loaded,
          browse: CategoryBrowse.resolve(
            tree,
            baseSlug: _baseSlug,
            pathSlugs: state.browse.pathSlugs,
            selectFirstOption: _baseSlug == null,
          ),
        ),
      ),
    );
  }
}
