import 'package:equatable/equatable.dart';

import 'featured_section_entity.dart';
import 'shop_entity.dart';

/// Result of applying a home filter chip — the shop list and featured-rail list
/// narrowed/sorted for the tapped filter. Returned by [SelectHomeFilterUseCase]
/// and folded into `HomeState.shops` + `HomeState.sections`.
class HomeFilterResult extends Equatable {
  const HomeFilterResult({required this.shops, required this.sections});

  /// Shops visible under the tapped filter (never empty — falls back to all).
  final List<ShopEntity> shops;

  /// Featured rails visible under the tapped filter (never empty — falls back
  /// to all).
  final List<FeaturedSectionEntity> sections;

  @override
  List<Object?> get props => [shops, sections];
}
