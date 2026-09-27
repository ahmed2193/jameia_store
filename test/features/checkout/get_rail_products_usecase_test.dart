import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_rail_products_usecase.dart';

import 'fake_checkout_catalog_repository.dart';

CatalogProductEntity _product(
  String id, {
  int price = 500,
  int stock = 5,
  CatalogProductType type = CatalogProductType.standard,
}) => CatalogProductEntity(
  id: id,
  slug: id,
  name: id,
  type: type,
  priceFils: price,
  compareAtFils: price + 200,
  stock: stock,
);

void main() {
  late FakeCheckoutCatalogRepository repository;
  late GetRailProductsUseCase useCase;

  setUp(() {
    repository = FakeCheckoutCatalogRepository();
    useCase = GetRailProductsUseCase(repository);
  });

  List<String> ids(Either<Failure, List<CatalogProductEntity>> result) =>
      result.getOrElse(() => const []).map((product) => product.id).toList();

  test('asks for the fetch limit', () async {
    await useCase(const GetRailProductsParams());

    expect(repository.calls, <String>[
      'rail:${GetRailProductsUseCase.fetchLimit}',
    ]);
  });

  test(
    'drops in-cart, unpriced, out-of-stock and duplicate products',
    () async {
      repository.products = <CatalogProductEntity>[
        _product('in-cart'),
        _product('milk-variants', price: 0, type: CatalogProductType.variant),
        _product('sold-out', stock: 0),
        _product('eggs'),
        _product('eggs'),
        _product('tea'),
      ];

      final result = await useCase(
        const GetRailProductsParams(excludeProductIds: <String>{'in-cart'}),
      );

      expect(ids(result), <String>['eggs', 'tea']);
    },
  );

  test('caps at the limit, keeping the server order', () async {
    repository.products = <CatalogProductEntity>[
      for (var i = 0; i < 15; i++) _product('p$i'),
    ];

    final result = await useCase(const GetRailProductsParams(limit: 3));

    expect(ids(result), <String>['p0', 'p1', 'p2']);
    expect(
      (await useCase(const GetRailProductsParams())).getOrElse(() => []),
      hasLength(GetRailProductsParams.defaultLimit),
    );
  });

  test('a failure passes through', () async {
    repository.railFailure = const NetworkFailure();

    final result = await useCase(const GetRailProductsParams());

    expect(result.isLeft(), isTrue);
  });
}
