// Product page data layer + domain rules, fed with the payloads the live host
// really sends (standard, variant and bundle products, reviews).
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/features/product_details/data/datasources/product_details_remote_data_source.dart';
import 'package:jameia_mart/src/features/product_details/data/mappers/product_detail_mapper.dart';
import 'package:jameia_mart/src/features/product_details/data/models/product_detail_model.dart';
import 'package:jameia_mart/src/features/product_details/data/models/product_reviews_model.dart';
import 'package:jameia_mart/src/features/product_details/data/repositories/product_details_repository_impl.dart';
import 'package:jameia_mart/src/features/product_details/domain/entities/product_detail.dart';

import '../../core/network/network_test_fakes.dart';

Map<String, dynamic> _fixture(String name) => jsonDecode(
  File('test/features/product_details/fixtures/$name').readAsStringSync(),
) as Map<String, dynamic>;

ProductDetail _detail(String name) =>
    ProductDetailModel.fromJson(_fixture(name)).toEntity();

class _ScriptedRemote implements ProductDetailsRemoteDataSource {
  Object? error;

  @override
  Future<ProductDetailModel> getProduct(String slug) async {
    final current = error;
    if (current != null) throw current;
    return ProductDetailModel.fromJson(_fixture('product_standard.json'));
  }

  @override
  Future<ProductReviewsModel> getReviews({
    required String slug,
    required int page,
    required int limit,
  }) async {
    final current = error;
    if (current != null) throw current;
    return ProductReviewsModel.fromJson(
      _fixture('reviews.json'),
      requestedPage: page,
    );
  }
}

void main() {
  final now = DateTime.utc(2026, 9, 17);

  group('standard product (live payload)', () {
    final detail = _detail('product_standard.json');

    test('maps the page', () {
      expect(detail.product.slug, 'basmati-rice-5kg');
      expect(detail.product.priceFils, 3250);
      expect(detail.description, isNotEmpty);
      expect(detail.gallery, isNotEmpty);
      expect(detail.brand?.slug, 'nestle');
      expect(detail.category?.slug, 'basmati-rice');
      expect(detail.category?.parentId, isNotNull);
      expect(detail.variants, isEmpty);
      expect(detail.recipes, isNotEmpty);
      expect(detail.recipes.first.slug, 'machboos');
    });

    test('buying rules of a standard product', () {
      expect(detail.needsVariant, isFalse);
      expect(detail.defaultVariant, isNull);
      expect(detail.canAdd(null), isTrue);
      expect(detail.stockOf(null), 80);
      expect(detail.unitPriceFils(variant: null, pro: false), 3250);
      expect(detail.compareAtFils(variant: null, now: now), 4063);
      expect(detail.discountPercent(variant: null, now: now), 20);
      expect(detail.lineTotalKd(variant: null, pro: false, quantity: 2), 6.5);
      expect(detail.proPriceFilsHint(variant: null), isNull);
    });
  });

  group('variant product (live payload)', () {
    final detail = _detail('product_variant.json');

    test('the card has no price; the variants carry it', () {
      expect(detail.product.type, CatalogProductType.variant);
      expect(detail.product.hasListPrice, isFalse);
      expect(detail.needsVariant, isTrue);
      expect([for (final v in detail.variants) v.id], ['v1', 'v2']);
      expect(detail.defaultVariant?.id, 'v1');
    });

    test('price, struck price and stock follow the chosen variant', () {
      final oneLitre = detail.variantById('v1');
      final twoLitres = detail.variantById('v2');

      expect(detail.canAdd(null), isFalse);
      expect(detail.canAdd(oneLitre), isTrue);
      expect(detail.unitPriceFils(variant: oneLitre, pro: false), 499);
      expect(detail.compareAtFils(variant: oneLitre, now: now), 550);
      expect(detail.discountPercent(variant: oneLitre, now: now), 9);
      expect(detail.unitPriceFils(variant: twoLitres, pro: false), 899);
      expect(detail.compareAtFils(variant: twoLitres, now: now), isNull);
      expect(detail.stockOf(twoLitres), 24);
      expect(detail.unitPriceFils(variant: null, pro: false), 0);
      expect(detail.variantById('nope'), isNull);
    });
  });

  group('bundle product (live payload)', () {
    final detail = _detail('product_bundle.json');

    test('maps the contents and the related products', () {
      expect(detail.product.type, CatalogProductType.bundle);
      expect(detail.needsVariant, isFalse);
      expect(detail.bundleItems, hasLength(3));
      expect(detail.bundleItems.first.product.slug, 'kdd-full-cream-milk');
      expect(detail.bundleItems.first.quantity, 1);
      expect(detail.bundleItems.first.unitPriceFils, 499);
      expect(detail.related, hasLength(2));
      expect(detail.canAdd(null), isTrue);
    });
  });

  group('tolerant parsing', () {
    test('a malformed nested row is skipped, a broken brand is dropped', () {
      final detail = ProductDetailModel.fromJson({
        '_id': 'p1',
        'slug': 'p-1',
        'name': 'P',
        'price': 1000,
        'stock': 3,
        'galleryUrls': 'not a list',
        'brand': {'name': 'no identity'},
        'category': null,
        'variants': [
          {'name': 'no id'},
          {'id': 'v1', 'name': 'ok', 'price': 500, 'stock': 0},
        ],
        'bundleItems': [
          {'quantity': 2},
        ],
        'related': ['x'],
      }).toEntity();

      expect(detail.brand, isNull);
      expect(detail.variants.single.id, 'v1');
      expect(detail.bundleItems, isEmpty);
      expect(detail.related, isEmpty);
      expect(detail.gallery, isEmpty);
    });

    test('a product without an identity is a ParsingException', () {
      expect(
        () => ProductDetailModel.fromJson({'name': 'x'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('an expired struck price and a Pro price', () {
      final detail = ProductDetailModel.fromJson({
        '_id': 'p1',
        'slug': 'p-1',
        'type': 'variant',
        'variants': [
          {
            'id': 'v1',
            'name': 'S',
            'price': 1000,
            'proPrice': 900,
            'compareAt': 1200,
            'compareAtExpiresAt': '2026-09-01T00:00:00.000Z',
            'stock': 5,
          },
        ],
      }).toEntity();
      final variant = detail.defaultVariant;

      expect(detail.compareAtFils(variant: variant, now: now), isNull);
      expect(detail.unitPriceFils(variant: variant, pro: true), 900);
      expect(detail.regularPriceFilsWhenPro(variant: variant, pro: true), 1000);
      expect(
        detail.regularPriceFilsWhenPro(variant: variant, pro: false),
        isNull,
      );
      expect(detail.proPriceFilsHint(variant: variant), 900);
    });
  });

  group('reviews (live payload)', () {
    test('maps rows + summary; merge de-dupes', () {
      final reviews = ProductReviewsModel.fromJson(_fixture('reviews.json'))
          .toEntity();

      expect(reviews.reviews.single.rating, 5);
      expect(reviews.reviews.single.customerName, 'Hessa A.');
      expect(reviews.reviews.single.createdAt.isUtc, isTrue);
      expect(reviews.ratingAverage, 5);
      expect(reviews.ratingCount, 1);
      expect(reviews.hasMore, isFalse);
      expect(reviews.merge(reviews).reviews, hasLength(1));
    });

    test('a review without a date is skipped; rating is clamped', () {
      final reviews = ProductReviewsModel.fromJson({
        'data': [
          {'_id': 'r1', 'rating': 9, 'createdAt': '2026-09-13T01:49:14.169Z'},
          {'_id': 'r2', 'rating': 4},
        ],
      }, requestedPage: 2).toEntity();

      expect(reviews.reviews.single.id, 'r1');
      expect(reviews.reviews.single.rating, 5);
      expect(reviews.page, 2);
    });
  });

  group('ProductDetailsRemoteDataSourceImpl', () {
    late FakeHttpClientAdapter adapter;

    ProductDetailsRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
      adapter = transport;
      return ProductDetailsRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = adapter),
      );
    }

    test('getProduct GETs /v1/products/:slug', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody(_fixture('product_standard.json')),
        ),
      );

      final product = await dataSource.getProduct('basmati-rice-5kg');

      expect(adapter.requests.single.method, 'GET');
      expect(
        adapter.requests.single.path,
        EndPoints.product('basmati-rice-5kg'),
      );
      expect(product.product.slug, 'basmati-rice-5kg');
    });

    test('getReviews GETs the reviews with page + limit', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(_fixture('reviews.json'))),
      );

      await dataSource.getReviews(slug: 'rice', page: 2, limit: 10);

      expect(adapter.requests.single.path, EndPoints.productReviews('rice'));
      expect(adapter.requests.single.queryParameters, {'page': 2, 'limit': 10});
    });

    test('an unknown slug is a NotFoundException', () {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: 404,
            statusMessage: 'RESOURCE_NOT_FOUND',
            errorMessage: 'Product not found',
          ),
        ),
      );

      expect(
        () => dataSource.getProduct('nope'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('ProductDetailsRepositoryImpl', () {
    test('maps to entities; 404 becomes ServerFailure(404)', () async {
      final remote = _ScriptedRemote();
      final repository = ProductDetailsRepositoryImpl(remote);

      final ok = await repository.getProduct('basmati-rice-5kg');
      expect(ok.isRight(), isTrue);

      remote.error = const NotFoundException('Product not found');
      final missing = await repository.getProduct('nope');
      final reviews = await repository.getReviews(
        slug: 'nope',
        page: 1,
        limit: 10,
      );

      expect(
        missing.swap().getOrElse(() => throw StateError('right')),
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 404),
      );
      expect(reviews.isLeft(), isTrue);
    });
  });
}
