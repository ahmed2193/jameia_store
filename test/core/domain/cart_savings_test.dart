// CartSavings: the one struck-total definition the cart bar and the
// checkout share, and the per-line savings getters it is built on.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_applied_offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_ref.dart';
import 'package:hero_mart/src/core/domain/entities/cart_savings.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_reward_entity.dart';

const CatalogProductEntity _rice = CatalogProductEntity(
  id: 'p1',
  slug: 'rice',
  name: 'Rice',
  image: 'https://cdn/rice.png',
  priceFils: 600,
  compareAtFils: 800,
  stock: 10,
);
const CatalogProductEntity _oil = CatalogProductEntity(
  id: 'p2',
  slug: 'oil',
  name: 'Oil',
  image: 'https://cdn/oil.png',
  priceFils: 900,
  stock: 10,
);

/// Rice × 2 at 0.600 (was 0.800), oil × 1 at 0.900 (no deal).
const CartLineEntity _riceLine = CartLineEntity(
  key: 'l1',
  product: _rice,
  quantity: 2,
  unitPriceFils: 600,
  compareAtFils: 800,
  lineTotalFils: 1200,
);
const CartLineEntity _oilLine = CartLineEntity(
  key: 'l2',
  product: _oil,
  quantity: 1,
  unitPriceFils: 900,
  lineTotalFils: 900,
);

CartEntity _cart({
  List<CartLineEntity> lines = const <CartLineEntity>[_riceLine, _oilLine],
  CartTotalsEntity totals = const CartTotalsEntity(
    subtotalFils: 2100,
    deliveryFeeFils: 500,
    baseDeliveryFeeFils: 500,
    totalFils: 2600,
  ),
  FulfillmentMode mode = FulfillmentMode.delivery,
  List<CartAppliedOfferEntity> applied = const <CartAppliedOfferEntity>[],
}) => CartEntity(
  lines: lines,
  totals: totals,
  fulfillmentMode: mode,
  appliedOffers: applied,
);

/// Free delivery on a 650 list fee, no fee charged.
const CartTotalsEntity _freeTotals = CartTotalsEntity(
  subtotalFils: 2100,
  freeDelivery: true,
  baseDeliveryFeeFils: 650,
  totalFils: 2100,
);

void main() {
  group('CartLineEntity savings', () {
    test('a line on sale saves (compareAt − unitPrice) × quantity', () {
      expect(_riceLine.unitSavingFils, 200);
      expect(_riceLine.savingFils, 400);
      expect(_riceLine.savingKd, 0.4);
      expect(_riceLine.savePercent, 25);
    });

    test('a line without a struck price saves nothing', () {
      expect(_oilLine.unitSavingFils, 0);
      expect(_oilLine.savingFils, 0);
      expect(_oilLine.savePercent, isNull);
    });

    test('savePercent rounds like the catalogue card', () {
      for (final (price, compareAt) in const <(int, int)>[
        (600, 800),
        (1000, 1500),
        (333, 1000),
        (665, 1000),
        (1250, 1300),
        (1, 3),
      ]) {
        final line = CartLineEntity(
          key: 'k',
          product: _rice,
          quantity: 1,
          unitPriceFils: price,
          compareAtFils: compareAt,
        );
        final card = CatalogProductEntity(
          id: 'p',
          slug: 'p',
          name: 'p',
          priceFils: price,
          compareAtFils: compareAt,
        );
        expect(
          line.savePercent,
          card.discountPercent,
          reason: '$price vs $compareAt',
        );
      }
    });
  });

  group('CartSavings.of', () {
    test('item savings, the list subtotal and the struck total', () {
      final savings = CartSavings.of(_cart());

      expect(savings.itemSavingsFils, 400);
      expect(savings.listSubtotalFils, 2500);
      expect(savings.discountFils, 0);
      expect(savings.waivedDeliveryFils, 0);
      expect(savings.totalSavingsFils, 400);
      expect(savings.struckTotalFils, 3000);
      expect(savings.struckTotalKd, 3.0);
    });

    test('the server discounts count too', () {
      final savings = CartSavings.of(
        _cart(
          totals: const CartTotalsEntity(
            subtotalFils: 2100,
            couponDiscountFils: 300,
            discountFils: 300,
            deliveryFeeFils: 500,
            totalFils: 2300,
          ),
        ),
      );

      expect(savings.totalSavingsFils, 700);
      expect(savings.struckTotalFils, 3000);
    });

    test('nothing saved: no struck total', () {
      final savings = CartSavings.of(
        _cart(lines: const <CartLineEntity>[_oilLine]),
      );

      expect(savings.hasSavings, isFalse);
      expect(savings.struckTotalFils, isNull);
      expect(savings.struckTotalKd, isNull);
      expect(savings.top, isNull);
    });

    test('free delivery waives the list fee', () {
      final savings = CartSavings.of(_cart(totals: _freeTotals));

      expect(savings.waivedDeliveryFils, 650);
      expect(savings.totalSavingsFils, 400 + 650);
      expect(savings.struckTotalFils, 2100 + 400 + 650);
    });

    test('without a list fee the quoted fee is the waiver', () {
      final savings = CartSavings.of(
        _cart(
          totals: const CartTotalsEntity(
            subtotalFils: 2100,
            freeDelivery: true,
            totalFils: 2100,
          ),
        ),
        quotedDeliveryFeeFils: 500,
      );

      expect(savings.waivedDeliveryFils, 500);
    });

    test('nothing is waived for pickup or an empty basket', () {
      expect(
        CartSavings.of(_cart(totals: _freeTotals, mode: FulfillmentMode.pickup))
            .waivedDeliveryFils,
        0,
      );
      expect(
        CartSavings.of(
          _cart(lines: const <CartLineEntity>[], totals: _freeTotals),
        ).waivedDeliveryFils,
        0,
      );
    });

    test('nothing is waived while a fee is still charged', () {
      final savings = CartSavings.of(
        _cart(
          totals: const CartTotalsEntity(
            subtotalFils: 2100,
            freeDelivery: true,
            deliveryFeeFils: 500,
            baseDeliveryFeeFils: 650,
            totalFils: 2600,
          ),
        ),
      );

      expect(savings.waivedDeliveryFils, 0);
    });

    test('an applied free-delivery offer that reports a discount is not '
        'counted twice', () {
      // Shape 1: the server counts the waiver inside the offer discount
      // (total == max(0, subtotal − discount) + deliveryFee holds).
      final counted = CartSavings.of(
        _cart(
          totals: const CartTotalsEntity(
            subtotalFils: 2100,
            offerDiscountFils: 650,
            discountFils: 650,
            freeDelivery: true,
            baseDeliveryFeeFils: 650,
            totalFils: 1450,
          ),
          applied: const <CartAppliedOfferEntity>[
            CartAppliedOfferEntity(
              offerId: 'o1',
              name: 'Free delivery over 5 KWD',
              discountFils: 650,
              reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
            ),
          ],
        ),
      );
      expect(counted.waivedDeliveryFils, 0);
      expect(counted.totalSavingsFils, 400 + 650);

      // Shape 2: the offer reports no discount; the waiver is the list fee.
      final separate = CartSavings.of(
        _cart(
          totals: _freeTotals,
          applied: const <CartAppliedOfferEntity>[
            CartAppliedOfferEntity(
              offerId: 'o1',
              name: 'Free delivery over 5 KWD',
              reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
            ),
          ],
        ),
      );
      expect(separate.waivedDeliveryFils, 650);
    });

    test('an offer discount the totals do not carry is the waiver', () {
      // The mock API's shape: the applied offer names the waiver (500),
      // offerDiscount stays 0 and no fee is charged.
      final savings = CartSavings.of(
        _cart(
          totals: const CartTotalsEntity(
            subtotalFils: 2100,
            freeDelivery: true,
            baseDeliveryFeeFils: 650,
            totalFils: 2100,
          ),
          applied: const <CartAppliedOfferEntity>[
            CartAppliedOfferEntity(
              offerId: 'o1',
              name: 'Free delivery over 5 KWD',
              discountFils: 500,
              reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
            ),
          ],
        ),
      );

      expect(savings.waivedDeliveryFils, 500);
      expect(savings.totalSavingsFils, 400 + 500);
      expect(savings.struckTotalFils, 2100 + 400 + 500);
    });

    test('a free-delivery flag with a fee still charged is not free', () {
      const charged = CartTotalsEntity(
        subtotalFils: 2100,
        freeDelivery: true,
        deliveryFeeFils: 500,
        totalFils: 2600,
      );
      const expressOnly = CartTotalsEntity(
        subtotalFils: 2100,
        freeDelivery: true,
        deliveryFeeFils: 300,
        expressSurchargeFils: 300,
        totalFils: 2400,
      );

      expect(charged.deliveryIsFree, isFalse);
      expect(_cart(totals: charged).deliveryQuoteFils, 500);
      // The express surcharge is not a delivery fee.
      expect(expressOnly.deliveryIsFree, isTrue);
      expect(_cart(totals: expressOnly).deliveryQuoteFils, 0);
      expect(_freeTotals.deliveryIsFree, isTrue);
    });

    test('the top saving is the biggest line; a tie keeps the first', () {
      const other = CartLineEntity(
        key: 'l3',
        product: CatalogProductEntity(
          id: 'p3',
          slug: 'tea',
          name: 'Tea',
          image: 'https://cdn/tea.png',
        ),
        quantity: 1,
        unitPriceFils: 600,
        compareAtFils: 1000,
        lineTotalFils: 600,
      );
      final savings = CartSavings.of(
        _cart(lines: const <CartLineEntity>[_riceLine, _oilLine, other]),
      );

      expect(savings.top?.ref, const CartLineRef('p1'));
      expect(savings.top?.imageUrl, 'https://cdn/rice.png');
      expect(savings.top?.quantity, 2);
      expect(savings.top?.savingFils, 400);
      expect(savings.top?.savingKd, 0.4);
    });

    test('one instance per cart snapshot and quoted fee', () {
      final cart = _cart(totals: _freeTotals);

      final first = CartSavings.of(cart);
      expect(identical(CartSavings.of(cart), first), isTrue);
      final quoted = CartSavings.of(cart, quotedDeliveryFeeFils: 1);
      expect(identical(quoted, first), isFalse);
      // Both entries stay: the cart tab and the checkout read one snapshot
      // with different fees without evicting each other.
      expect(identical(CartSavings.of(cart), first), isTrue);
      expect(
        identical(CartSavings.of(cart, quotedDeliveryFeeFils: 1), quoted),
        isTrue,
      );
      // An equal but distinct snapshot is computed again, to the same value.
      final twin = _cart(totals: _freeTotals);
      expect(CartSavings.of(twin), first);
    });
  });
}
