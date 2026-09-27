import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_ref.dart';
import 'package:hero_mart/src/core/domain/entities/cart_offer_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_thumbs.dart';

CartLineEntity _line(
  String id, {
  int quantity = 1,
  CartLineIssue issue = CartLineIssue.none,
}) => CartLineEntity(
  key: 'k$id',
  product: CatalogProductEntity(
    id: id,
    slug: id,
    name: id,
    image: 'https://cdn/$id.png',
  ),
  quantity: quantity,
  issue: issue,
);

const CartOfferLineEntity _gift = CartOfferLineEntity(
  key: 'g1',
  offerId: 'o1',
  offerName: 'Free milk',
  quantity: 1,
  product: CatalogProductEntity(
    id: 'milk',
    slug: 'milk',
    name: 'Milk',
    image: 'https://cdn/milk.png',
  ),
);

void main() {
  test('pieces count paid lines and gifts', () {
    final cart = CartEntity(
      lines: <CartLineEntity>[_line('rice', quantity: 2), _line('oil')],
      offerLines: const <CartOfferLineEntity>[_gift],
    );
    final thumbs = CheckoutThumbs.of(cart, max: 5);

    expect(thumbs.totalPieces, 4);
    // The count alone, without building a strip.
    expect(CheckoutThumbs.piecesOf(cart), 4);
    expect(thumbs.slots.map((slot) => slot.quantity), <int>[2, 1, 1]);
  });

  test('paid lines first, then gifts, capped at max', () {
    final cart = CartEntity(
      lines: <CartLineEntity>[_line('a'), _line('b'), _line('c')],
      offerLines: const <CartOfferLineEntity>[_gift],
    );

    final two = CheckoutThumbs.of(cart, max: 2);
    expect(two.slots.map((slot) => slot.id), <Object>[
      const CartLineRef('a'),
      const CartLineRef('b'),
    ]);
    expect(two.totalPieces, 4);

    final all = CheckoutThumbs.of(cart, max: 9); // clamped to maxSlots
    expect(all.slots, hasLength(4));
    expect(all.slots.last.id, 'gift:g1');
    expect(all.slots.last.isGift, isTrue);
    expect(all.slots.last.imageUrl, 'https://cdn/milk.png');

    expect(CheckoutThumbs.of(cart, max: 0).slots, hasLength(1));
  });

  test('equal carts give equal strips', () {
    CartEntity cart() =>
        CartEntity(lines: <CartLineEntity>[_line('rice', quantity: 2)]);

    expect(
      CheckoutThumbs.of(cart(), max: 3),
      CheckoutThumbs.of(cart(), max: 3),
    );
    expect(
      CheckoutThumbs.of(cart(), max: 3),
      isNot(
        CheckoutThumbs.of(
          CartEntity(lines: <CartLineEntity>[_line('rice', quantity: 3)]),
          max: 3,
        ),
      ),
    );
  });

  test('blockingCount counts the lines that block the order; every thumb '
      'with an issue is flagged', () {
    final cart = CartEntity(
      lines: <CartLineEntity>[
        _line('a', issue: CartLineIssue.outOfStock),
        _line('b'),
        _line('c', issue: CartLineIssue.quantityReduced),
      ],
    );
    final thumbs = CheckoutThumbs.of(cart, max: 5);

    // Only the out-of-stock line blocks the order; a cut-back quantity
    // does not.
    expect(thumbs.blockingCount, 1);
    expect(CheckoutThumbs.blockingOf(cart), 1);
    expect(thumbs.slots.map((slot) => slot.hasIssue), <bool>[
      true,
      false,
      true,
    ]);
  });
}
