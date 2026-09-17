// Cart clean-arch repository tests.
//
// Primary guard: the emit-swallow bug. The old bare cubit mutated a shared
// mutable CartItem in place (`qty += 1`), so the next CartState compared EQUAL to
// the previous one and Bloc dropped the emit — a second same-line add never
// reached the UI. With an immutable CartItem + value equality, two successive
// snapshots must differ, so the emit fires.

import 'package:flutter_test/flutter_test.dart';

import 'package:jameia_mart/src/core/data/jameia_repository.dart';
import 'package:jameia_mart/src/core/data/models/models.dart';
import 'package:jameia_mart/src/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:jameia_mart/src/features/cart/data/models/cart_model.dart';
import 'package:jameia_mart/src/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';

/// In-memory datasource — avoids loading assets / shared_preferences.
class _FakeLocal implements CartLocalDataSource {
  CartModel? stored;
  @override
  CartModel? read() => stored;
  @override
  Future<void> write(CartModel model) async => stored = model;
  @override
  Future<void> clear() async => stored = null;
}

const _product = Product(
  id: 'p1',
  name: 'Test Product',
  image: '',
  price: 2.500,
  originalPrice: 0,
  desc: '',
  soldCount: 0,
  kcal: 0,
);

CartSnapshot _snap(dynamic either) =>
    either.getOrElse(() => const CartSnapshot()) as CartSnapshot;

void main() {
  group('CartItem immutability (root emit-bug fix)', () {
    test('copyWith yields a new, value-unequal instance', () {
      const a = CartItem(product: _product, shopId: 'jameia', qty: 1);
      final b = a.copyWith(qty: 2);
      expect(a == b, isFalse); // different qty → different value
      expect(a.copyWith(qty: 1) == a, isTrue); // same fields → equal
      expect(identical(a, b), isFalse);
    });
  });

  group('CartRepositoryImpl (offline)', () {
    late _FakeLocal local;
    late CartRepositoryImpl repo;

    setUp(() {
      local = _FakeLocal();
      // addLine never touches the catalogue, so an unloaded JameiaRepository is fine.
      repo = CartRepositoryImpl(local: local, catalog: JameiaRepository());
    });

    test(
      'adding the same line twice increments qty AND changes the snapshot',
      () async {
        final s1 = _snap(
          await repo.addLine(product: _product, shopId: 'jameia'),
        );
        final s2 = _snap(
          await repo.addLine(product: _product, shopId: 'jameia'),
        );

        expect(s1.items['p1']!.qty, 1);
        expect(s2.items['p1']!.qty, 2); // second add is NOT swallowed
        expect(s1 == s2, isFalse); // snapshots differ → Bloc emit fires
        expect(s2.items['p1']!.lineTotal, closeTo(5.0, 1e-9));
      },
    );

    test('qty add param adds N units at once', () async {
      final s = _snap(
        await repo.addLine(product: _product, shopId: 'jameia', qty: 3),
      );
      expect(s.items['p1']!.qty, 3);
    });

    test('updateQty to 0 removes the line and clears shopId', () async {
      await repo.addLine(product: _product, shopId: 'jameia');
      final s = _snap(await repo.updateQty(lineKey: 'p1', qty: 0));
      expect(s.items.containsKey('p1'), isFalse);
      expect(s.shopId, isNull);
    });

    test('clear empties the cart and the persisted store', () async {
      await repo.addLine(product: _product, shopId: 'jameia');
      final s = _snap(await repo.clear());
      expect(s.items, isEmpty);
      expect(s.shopId, isNull);
      expect(local.stored, isNull);
    });

    test('mutations are mirrored to the local datasource', () async {
      await repo.addLine(product: _product, shopId: 'jameia', qty: 2);
      // Fire-and-forget persist runs synchronously here (no await gap).
      expect(local.stored, isNotNull);
      expect(local.stored!.shopId, 'jameia');
      expect(local.stored!.lines.single.qty, 2);
      expect(local.stored!.lines.single.productId, 'p1');
    });
  });

  group('CartModel serialization (persistence round-trip)', () {
    test('toJson/fromJson preserves lines', () {
      const model = CartModel(
        shopId: 'jameia',
        lines: [
          CartLineModel(
            productId: 'p1',
            shopId: 'jameia',
            qty: 2,
            variantSku: 'sku-m',
            unitPriceOverride: 1.75,
          ),
        ],
      );
      final restored = CartModel.fromJson(model.toJson());
      expect(restored.shopId, 'jameia');
      expect(restored.lines.single.productId, 'p1');
      expect(restored.lines.single.qty, 2);
      expect(restored.lines.single.variantSku, 'sku-m');
      expect(restored.lines.single.unitPriceOverride, 1.75);
    });
  });
}
