// The rail is settled before the checkout's content first paints: it loads
// once, hides itself when empty / failing, and a reply slower than
// `settleLimit` is dropped so the rail never pops in above the fold.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_rail_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_rail_state.dart';

import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';

const CatalogProductEntity _eggs = CatalogProductEntity(
  id: 'eggs',
  slug: 'eggs',
  name: 'Eggs',
  priceFils: 900,
  compareAtFils: 1200,
  stock: 4,
);
const CatalogProductEntity _rice = CatalogProductEntity(
  id: 'rice',
  slug: 'rice',
  name: 'Rice',
  priceFils: 1500,
  compareAtFils: 1800,
  stock: 9,
);

void main() {
  late FakeCheckoutCatalogRepository repository;
  late CheckoutRailCubit cubit;

  setUp(() {
    repository = FakeCheckoutCatalogRepository(
      products: const <CatalogProductEntity>[_eggs, _rice],
    );
    cubit = buildRailCubit(repository);
  });

  tearDown(() => cubit.close());

  test('starts loading, then shows the products not in the basket', () async {
    expect(cubit.state.status, CheckoutRailStatus.loading);
    expect(cubit.state.isSettled, isFalse);

    await cubit.load(excludeProductIds: const <String>{'rice'});

    expect(cubit.state.status, CheckoutRailStatus.ready);
    expect(cubit.state.products, const <CatalogProductEntity>[_eggs]);
    expect(cubit.state.isSettled, isTrue);
  });

  test('nothing left to show: hidden', () async {
    await cubit.load(excludeProductIds: const <String>{'rice', 'eggs'});

    expect(cubit.state.status, CheckoutRailStatus.hidden);
  });

  test('a failure: hidden', () async {
    repository.railFailure = const NetworkFailure();

    await cubit.load(excludeProductIds: const <String>{});

    expect(cubit.state.status, CheckoutRailStatus.hidden);
  });

  test('a second load is ignored', () async {
    await cubit.load(excludeProductIds: const <String>{});
    repository.products = const <CatalogProductEntity>[];
    await cubit.load(excludeProductIds: const <String>{});

    expect(repository.calls, hasLength(1));
    expect(cubit.state.status, CheckoutRailStatus.ready);
  });

  test(
    'a reply after the settle limit is dropped: the rail stays hidden',
    () async {
      final gate = Completer<void>();
      repository.railGate = gate;
      final states = <CheckoutRailStatus>[];
      final sub = cubit.stream.listen((state) => states.add(state.status));
      addTearDown(sub.cancel);

      // Real time: the load gives up after CheckoutRailCubit.settleLimit.
      await cubit.load(excludeProductIds: const <String>{});
      expect(cubit.state.status, CheckoutRailStatus.hidden);

      gate.complete(); // the slow reply lands now
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, CheckoutRailStatus.hidden);
      expect(states, <CheckoutRailStatus>[CheckoutRailStatus.hidden]);
    },
  );
}
