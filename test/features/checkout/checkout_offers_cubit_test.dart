import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_offers_state.dart';

import 'checkout_test_harness.dart';
import 'fake_checkout_catalog_repository.dart';

void main() {
  const offer = OfferEntity(
    id: 'free',
    name: 'Free delivery over 5 KWD',
    stackable: true,
  );

  test('loads the store offers', () async {
    final repository = FakeCheckoutCatalogRepository(
      offers: const <OfferEntity>[offer],
    );
    final cubit = buildOffersCubit(repository);
    expect(cubit.state.status, CheckoutOffersStatus.loading);

    await cubit.load();

    expect(repository.calls, <String>['offers']);
    expect(cubit.state.status, CheckoutOffersStatus.ready);
    expect(cubit.state.offers, const <OfferEntity>[offer]);
    await cubit.close();
  });

  test(
    'a failure is ready with no offers (the cart builds the cards)',
    () async {
      final repository = FakeCheckoutCatalogRepository(
        offers: const <OfferEntity>[offer],
      )..offersFailure = const NetworkFailure();
      final cubit = buildOffersCubit(repository);

      await cubit.load();

      expect(cubit.state.status, CheckoutOffersStatus.ready);
      expect(cubit.state.offers, isEmpty);
      await cubit.close();
    },
  );
}
