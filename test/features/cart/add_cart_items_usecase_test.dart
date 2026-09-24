import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_item_request.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/add_cart_items_usecase.dart';

import 'fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;
  late AddCartItemsUseCase useCase;

  setUp(() {
    repository = FakeCartRepository();
    useCase = AddCartItemsUseCase(repository);
  });

  tearDown(() => repository.dispose());

  test('drops invalid rows and sends the rest in one request', () async {
    final result = await useCase(
      const AddCartItemsParams(<CartItemRequest>[
        CartItemRequest(productId: 'p1', quantity: 2),
        CartItemRequest(productId: '', quantity: 1), // no product
        CartItemRequest(productId: 'p3', quantity: 0), // nothing to add
      ]),
    );

    expect(result.isRight(), isTrue);
    expect(repository.calls, <String>['addItems:1']);
  });

  test('an empty (or all-invalid) request never reaches the server', () async {
    final result = await useCase(
      const AddCartItemsParams(<CartItemRequest>[
        CartItemRequest(productId: '', quantity: 1),
      ]),
    );

    expect(result.isRight(), isTrue);
    expect(repository.calls, isEmpty);
  });

  test('more rows than one request carries go out in batches', () async {
    // A reorder of a big order must not silently lose its tail.
    const overflow = 12;
    final items = <CartItemRequest>[
      for (var i = 0; i < CartItemRequest.maxItemsPerRequest + overflow; i++)
        CartItemRequest(productId: 'p$i', quantity: 1),
    ];

    final result = await useCase(AddCartItemsParams(items));

    expect(result.isRight(), isTrue);
    expect(repository.calls, <String>[
      'addItems:${CartItemRequest.maxItemsPerRequest}',
      'addItems:$overflow',
    ]);
  });

  test('a refused batch stops the rest', () async {
    repository.failure = const ServerFailure('nope', statusCode: 400);
    final items = <CartItemRequest>[
      for (var i = 0; i < CartItemRequest.maxItemsPerRequest + 1; i++)
        CartItemRequest(productId: 'p$i', quantity: 1),
    ];

    final result = await useCase(AddCartItemsParams(items));

    expect(result.isLeft(), isTrue);
    expect(repository.calls, hasLength(1));
  });
}
