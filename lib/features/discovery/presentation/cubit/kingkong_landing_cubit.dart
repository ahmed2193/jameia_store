import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// State for the KeeTa `homepage_kingkong_page` (category/kingKongPage) — the
/// KingKong category landing reached from a home KingKong icon. Holds the
/// sub-category chip row and the filtered [Shop] feed for the active chip.
class KingKongLandingState {
  const KingKongLandingState({
    required this.subCategories,
    required this.activeSub,
    required this.shops,
  });

  /// Sub-category chips under the category title (`subCategory` rail).
  final List<String> subCategories;

  /// Index of the selected sub-category chip.
  final int activeSub;

  /// Shop cards feed for the active sub-category.
  final List<Shop> shops;

  KingKongLandingState copyWith({
    int? activeSub,
    List<Shop>? shops,
  }) {
    return KingKongLandingState(
      subCategories: subCategories,
      activeSub: activeSub ?? this.activeSub,
      shops: shops ?? this.shops,
    );
  }
}

/// Page-scoped cubit (constructed inline in the screen via `BlocProvider`, NOT
/// registered in the service locator). Serves dummy data straight off
/// [KeetaRepository].
///
/// The KingKong landing is a category page: [categoryId] picks the base shop
/// pool (food → restaurants, grocery/pharmacy/flowers → groceries, anything else
/// → all shops), and the sub-category chips re-rank/filter that pool.
class KingKongLandingCubit extends Cubit<KingKongLandingState> {
  KingKongLandingCubit(this._repo, {required String categoryId})
      : _categoryId = categoryId,
        super(
          KingKongLandingState(
            subCategories: _subCategoriesFor(categoryId),
            activeSub: 0,
            shops: _basePoolFor(_repo, categoryId),
          ),
        );

  final KeetaRepository _repo;
  final String _categoryId;

  void selectSub(int index) {
    if (index == state.activeSub) return;
    emit(state.copyWith(activeSub: index, shops: _shopsFor(index)));
  }

  List<Shop> _shopsFor(int sub) {
    final base = _basePoolFor(_repo, _categoryId);
    // Chip 0 = "All" → the unfiltered base pool.
    if (sub == 0) return base;
    return switch (state.subCategories[sub]) {
      'Free delivery' => base.where((s) => s.freeDelivery).toList(),
      'Rating 4.5+' => base.where((s) => s.rating >= 4.5).toList(),
      'Nearby' => [base]
          .map((l) => l..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)))
          .first,
      'Fast delivery' => [base]
          .map((l) => l..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)))
          .first,
      _ => base,
    };
  }

  static List<Shop> _basePoolFor(KeetaRepository repo, String categoryId) {
    return switch (categoryId) {
      'k1' || 'k5' => repo.restaurants, // Food / Meal for One
      'k2' || 'k3' || 'k7' => repo.groceries, // Grocery / Pharmacy / Flowers
      _ => repo.shops,
    };
  }

  static List<String> _subCategoriesFor(String categoryId) {
    return const ['All', 'Nearby', 'Rating 4.5+', 'Free delivery', 'Fast delivery'];
  }
}
