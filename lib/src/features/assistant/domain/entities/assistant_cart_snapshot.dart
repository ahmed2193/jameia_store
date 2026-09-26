import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';

/// Name + picture of one cart line, for the summary card's thumbnails.
class AssistantCartPreviewItem extends Equatable {
  const AssistantCartPreviewItem({required this.name, this.imageUrl = ''});

  final String name;
  final String imageUrl;

  @override
  List<Object?> get props => [name, imageUrl];
}

/// The cart as a `cart_summary` block printed it — a picture taken when the
/// reply was written, NOT the live cart (that is `CartCubit`'s, refreshed
/// after a confirmed proposal). Holds only what the card shows.
class AssistantCartSnapshot extends Equatable {
  const AssistantCartSnapshot({
    this.itemCount = 0,
    this.totalFils = 0,
    this.minOrderFils = 0,
    this.meetsMinOrder = true,
    this.previews = const <AssistantCartPreviewItem>[],
  });

  /// The card shows at most this many thumbnails.
  static const int maxPreviews = 4;

  /// Units across every line.
  final int itemCount;
  final int totalFils;

  /// `0` when the store has no minimum.
  final int minOrderFils;
  final bool meetsMinOrder;

  /// At most [maxPreviews] lines, in cart order.
  final List<AssistantCartPreviewItem> previews;

  bool get isEmpty => itemCount == 0;

  double get totalKd => totalFils / CatalogProductEntity.filsPerDinar;

  /// What is still missing to reach the minimum order; `0` once it is met.
  int get missingForMinOrderFils {
    if (meetsMinOrder || minOrderFils <= totalFils) return 0;
    return minOrderFils - totalFils;
  }

  double get missingForMinOrderKd =>
      missingForMinOrderFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    itemCount,
    totalFils,
    minOrderFils,
    meetsMinOrder,
    previews,
  ];
}
