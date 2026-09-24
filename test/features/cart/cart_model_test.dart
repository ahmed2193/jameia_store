import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/data/mappers/catalog_product_mapper.dart';
import 'package:jameia_mart/src/features/cart/data/mappers/cart_mapper.dart';
import 'package:jameia_mart/src/features/cart/data/models/cart_mirror_model.dart';
import 'package:jameia_mart/src/features/cart/data/models/cart_model.dart';

import 'cart_test_fixtures.dart';

void main() {
  group('CartModel.fromJson', () {
    test('reads the whole cart and maps it to the entity', () {
      final cart = CartModel.fromJson(
        cartJson(coupon: <String, dynamic>{'code': 'WELCOME', 'discount': 250}),
      ).toEntity();

      expect(cart.cartToken, 'ct-1');
      expect(cart.itemCount, 2);
      expect(cart.fulfillmentMode, FulfillmentMode.delivery);
      expect(cart.lines.single.product.name, 'Basmati rice');
      // The mapper drops the raw tag ids the backend leaks.
      expect(cart.lines.single.product.tags, <String>['fresh']);
      expect(cart.coupon?.code, 'WELCOME');
      expect(cart.totals.subtotalFils, 3000);
      expect(cart.expressOffered, isTrue);
      expect(cart.canCheckout, isTrue);
    });

    test('throws without a cartToken', () {
      expect(
        () => CartModel.fromJson(const <String, dynamic>{'itemCount': 1}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('skips a malformed line instead of failing the cart', () {
      final cart = CartModel.fromJson(
        cartJson(
          lines: <Map<String, dynamic>>[
            lineJson(),
            <String, dynamic>{'quantity': 3}, // no key, no product
          ],
        ),
      ).toEntity();

      expect(cart.lines, hasLength(1));
    });

    test('maps the line issue and blocks checkout on an unavailable line', () {
      final cart = CartModel.fromJson(
        cartJson(
          lines: <Map<String, dynamic>>[lineJson(issue: 'out_of_stock')],
        ),
      ).toEntity();

      expect(cart.lines.single.issue, CartLineIssue.outOfStock);
      expect(cart.hasBlockingIssue, isTrue);
      expect(cart.checkoutBlock, CartCheckoutBlock.lineIssue);
    });

    test('an unknown issue is `other` and does not block checkout', () {
      final cart = CartModel.fromJson(
        cartJson(lines: <Map<String, dynamic>>[lineJson(issue: 'weird')]),
      ).toEntity();

      expect(cart.lines.single.issue, CartLineIssue.other);
      expect(cart.canCheckout, isTrue);
    });

    test('below the minimum order blocks checkout with the shortfall', () {
      final cart = CartModel.fromJson(
        cartJson(minOrder: 5000, meetsMinOrder: false),
      ).toEntity();

      expect(cart.checkoutBlock, CartCheckoutBlock.belowMinOrder);
      expect(cart.totals.shortfallFils, 2000);
    });

    test('a closed branch and no capacity block checkout', () {
      expect(
        CartModel.fromJson(cartJson(branchOpen: false))
            .toEntity()
            .checkoutBlock,
        CartCheckoutBlock.branchClosed,
      );
      expect(
        CartModel.fromJson(cartJson(capacityAvailable: false))
            .toEntity()
            .checkoutBlock,
        CartCheckoutBlock.noCapacity,
      );
    });

    test('round-trips through toJson for the device mirror', () {
      final original = CartModel.fromJson(cartJson());
      final restored = CartModel.fromJson(original.toJson());

      expect(restored.toEntity(), original.toEntity());
    });
  });

  group('CartMirrorModel', () {
    test('round-trips the owner, the cart and the pending changes', () {
      final mirror = CartMirrorModel(
        ownerId: 'c1',
        cart: CartModel.fromJson(cartJson()),
        pending: <CartPendingChangeModel>[
          CartPendingChangeModel(
            productId: 'p9',
            delta: 2,
            product: testProduct.toModel(),
          ),
        ],
      );

      final restored = CartMirrorModel.fromJson(mirror.toJson());

      expect(restored.ownerId, 'c1');
      expect(restored.cart?.cartToken, 'ct-1');
      expect(restored.pending.single.productId, 'p9');
      expect(restored.pending.single.delta, 2);
      expect(restored.pending.single.product?.name, 'Basmati rice');
    });

    test('throws without an owner', () {
      expect(
        () => CartMirrorModel.fromJson(const <String, dynamic>{}),
        throwsA(isA<ParsingException>()),
      );
    });
  });
}
