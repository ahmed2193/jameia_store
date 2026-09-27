import 'package:equatable/equatable.dart';

import 'cart_line_ref.dart';
import 'catalog_product_entity.dart';

/// The cart line that saves the most against its struck price — what the
/// checkout's "KD x off" hint points at. Money in fils.
class CartTopSaving extends Equatable {
  const CartTopSaving({
    required this.ref,
    required this.imageUrl,
    required this.quantity,
    required this.savingFils,
  });

  final CartLineRef ref;
  final String imageUrl;
  final int quantity;

  /// The whole line's saving (`(compareAt − unitPrice) × quantity`).
  final int savingFils;

  double get savingKd => savingFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [ref, imageUrl, quantity, savingFils];
}
