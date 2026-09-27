import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/domain/repositories/checkout_catalog_repository.dart';

/// Scripted checkout catalogue: records the calls (`'rail:<limit>'`,
/// `'offers'`), can hold the rail read open on [railGate], and can fail
/// either read once.
class FakeCheckoutCatalogRepository implements CheckoutCatalogRepository {
  FakeCheckoutCatalogRepository({
    this.products = const <CatalogProductEntity>[],
    this.offers = const <OfferEntity>[],
  });

  final List<String> calls = <String>[];

  List<CatalogProductEntity> products;
  List<OfferEntity> offers;

  Failure? railFailure;
  Failure? offersFailure;

  /// When set, the next rail read waits on it (a slow network).
  Completer<void>? railGate;

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> getRailProducts({
    required int limit,
  }) async {
    calls.add('rail:$limit');
    final gate = railGate;
    if (gate != null) {
      railGate = null;
      await gate.future;
    }
    final failure = railFailure;
    railFailure = null;
    return failure == null ? Right(products) : Left(failure);
  }

  @override
  Future<Either<Failure, List<OfferEntity>>> getStoreOffers() async {
    calls.add('offers');
    final failure = offersFailure;
    offersFailure = null;
    return failure == null ? Right(offers) : Left(failure);
  }
}
