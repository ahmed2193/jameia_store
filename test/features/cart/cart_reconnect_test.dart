// The cart when the connection comes back: the taps still owed go out at
// once; with none owed the cart is read again. Silent either way — a failed
// catch-up adds no failure of its own (the snapshot reports a failed sync).
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';

import 'cart_page_harness.dart';
import 'fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;
  late CartCubit cubit;

  setUp(() async {
    repository = FakeCartRepository();
    cubit = buildCartCubit(repository);
    await pumpEventQueue();
    repository.calls.clear();
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('taps still owed go out at once', () async {
    repository.push(
      const CartSnapshot(hasPendingChanges: true, isUnsynced: true),
    );
    await pumpEventQueue();

    await cubit.onReconnected();

    expect(repository.calls, ['flush']);
  });

  test('nothing owed: the cart is read again', () async {
    await cubit.onReconnected();

    expect(repository.calls, ['fetch']);
  });

  test('a failed catch-up adds no failure of its own', () async {
    repository.failure = const NetworkFailure();

    await cubit.onReconnected();

    expect(cubit.state.failure, isNull);
    expect(cubit.state.isBusy, isFalse, reason: 'no busy action shown');
  });
}
