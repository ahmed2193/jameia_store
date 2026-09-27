// `GET /v1/offers` → `branchIds`: parsed onto the core offer, and
// `availableAt` tells which branches an offer runs at.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/mappers/offer_mapper.dart';
import 'package:jameia_mart/src/core/data/models/offer_model.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';

Map<String, dynamic> _offer({Object? branchIds}) => <String, dynamic>{
  '_id': 'o1',
  'name': '10% off over 15 KWD',
  'status': 'active',
  'trigger': <String, dynamic>{'type': 'cart_subtotal', 'min': 15000},
  'reward': <String, dynamic>{
    'type': 'percentage_discount',
    'percent': 10,
    'maxDiscount': 3000,
  },
  'priority': 1,
  'stackable': true,
  'branchIds': ?branchIds,
  'endsAt': '2027-12-31T20:59:59.000Z',
};

void main() {
  test('branch ids are parsed; non-string rows are skipped', () {
    final offer = OfferModel.fromJson(
      _offer(branchIds: <Object?>['b1', 7, null, '', 'b2']),
    ).toEntity();

    expect(offer.branchIds, <String>['b1', 'b2']);
  });

  test('a missing or malformed list means every branch', () {
    expect(OfferModel.fromJson(_offer()).toEntity().branchIds, isEmpty);
    expect(
      OfferModel.fromJson(_offer(branchIds: 'b1')).toEntity().branchIds,
      isEmpty,
    );
  });

  test('availableAt', () {
    const everywhere = OfferEntity(id: 'o1', name: 'n');
    const some = OfferEntity(
      id: 'o2',
      name: 'n',
      branchIds: <String>['b1', 'b2'],
    );

    expect(everywhere.availableAt(null), isTrue);
    expect(everywhere.availableAt('b9'), isTrue);
    expect(some.availableAt('b1'), isTrue);
    expect(some.availableAt('b9'), isFalse);
    // Limited to some branches: not while the branch is unknown.
    expect(some.availableAt(null), isFalse);
  });

  test('branch ids are part of equality', () {
    expect(
      const OfferEntity(id: 'o', name: 'n', branchIds: <String>['b1']),
      isNot(const OfferEntity(id: 'o', name: 'n')),
    );
  });
}
