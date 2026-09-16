import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/home_feed.dart';

/// Read boundary for the home tab. Offline, the feed resolves from the in-memory
/// catalogue (mapped to the feature's framework-free entities); it still returns
/// `Either<Failure, T>` so the presentation layer handles failure uniformly.
abstract class HomeRepository {
  /// Load the whole home feed snapshot (operation header, kingkong, rails,
  /// carousels, tiles, benefits, filters, featured sections, store settings).
  Future<Either<Failure, HomeFeed>> getHomeFeed();

  /// Resolve the shop-screen navigation argument for a home featured product's
  /// SKU: `catId~subId~rankId` when the product is located in the taxonomy, else
  /// the first category id (or the raw sku as a last resort). Pure in-memory
  /// lookup — the old inline `sl<KeetaRepository>().locationOfSku` read on the
  /// home screen now routes through here so presentation drops that dependency.
  String shopArgForProduct(String sku);
}
