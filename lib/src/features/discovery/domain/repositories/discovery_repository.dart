import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/shop_entity.dart';

/// Raw channel-source bundle: the full shop feed + filter-chip labels. Read once
/// per page open; the use cases derive scenes / curate from it.
typedef DiscoveryCatalogue = ({List<ShopEntity> shops, List<String> filters});

/// Read boundary for the discovery channel surfaces. Offline, every method
/// resolves off the scripted catalogue; they still return `Either<Failure, T>`
/// so the presentation layer handles failure uniformly.
abstract class DiscoveryRepository {
  /// Full shop feed + filter labels (channel list + meal-for-one seed).
  Future<Either<Failure, DiscoveryCatalogue>> catalogue();

  /// Full shop feed (pickup source + fixed-price default-host fallback).
  Future<Either<Failure, List<ShopEntity>>> shops();

  /// Restaurant-only pool (KingKong food / meal categories).
  Future<Either<Failure, List<ShopEntity>>> restaurants();

  /// Grocery-only pool (KingKong grocery / pharmacy / flowers categories).
  Future<Either<Failure, List<ShopEntity>>> groceries();

  /// A single shop by id (fixed-price flash host).
  Future<Either<Failure, ShopEntity>> shopById(String id);
}
