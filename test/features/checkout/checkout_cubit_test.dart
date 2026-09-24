import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_branches_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_delivery_slots_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/place_order_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/select_delivery_address_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/select_pickup_branch_usecase.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';

import 'fake_checkout_repository.dart';

import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_state.dart';

void main() {
  late FakeCheckoutRepository repository;

  CheckoutCubit build() {
    repository = FakeCheckoutRepository();
    return CheckoutCubit(
      getBranches: GetBranchesUseCase(repository),
      getDeliverySlots: GetDeliverySlotsUseCase(repository),
      selectDeliveryAddress: SelectDeliveryAddressUseCase(repository),
      selectPickupBranch: SelectPickupBranchUseCase(repository),
      placeOrder: PlaceOrderUseCase(repository),
    );
  }

  test('start loads pickup branches and bookable days only', () async {
    final cubit = build();

    await cubit.start();

    expect(cubit.state.status, CheckoutStatus.ready);
    expect(cubit.state.branches.map((branch) => branch.id), <String>['b1']);
    expect(cubit.state.slotDays, hasLength(1));
    expect(cubit.state.hasScheduledSlots, isTrue);
    await cubit.close();
  });

  test('the default address is selected on the server right away', () async {
    final cubit = build();

    await cubit.start(defaultAddressId: 'a1');

    expect(repository.calls, contains('address:a1'));
    expect(cubit.state.selection?.addressId, 'a1');
    expect(cubit.state.draft.addressId, 'a1');
    await cubit.close();
  });

  test('a load failure shows the error view and can be retried', () async {
    final cubit = build();
    repository.branchesFailure = const NetworkFailure();

    await cubit.start();

    expect(cubit.state.status, CheckoutStatus.error);
    expect(cubit.state.loadFailure, isA<NetworkFailure>());

    await cubit.retry();
    expect(cubit.state.status, CheckoutStatus.ready);
    await cubit.close();
  });

  test('a selection that lands after a newer one is dropped', () async {
    final cubit = build();
    await cubit.start();

    final gate = Completer<void>();
    repository.selectGate = gate;
    final stale = cubit.selectAddress('a1');
    await Future<void>.delayed(Duration.zero);
    await cubit.selectAddress('a2'); // newer choice wins
    gate.complete();
    await stale;

    expect(cubit.state.selection?.addressId, 'a2');
    expect(cubit.state.isSelecting, isFalse);
    await cubit.close();
  });

  test('switching to pickup re-selects the known branch', () async {
    final cubit = build();
    await cubit.start();
    await cubit.selectBranch('b1');
    await cubit.setMode(FulfillmentMode.delivery);
    repository.calls.clear();

    await cubit.setMode(FulfillmentMode.pickup);

    expect(repository.calls, <String>['branch:b1']);
    expect(cubit.state.draft.isPickup, isTrue);
    await cubit.close();
  });

  test(
    'switching to a mode with no destination clears the selection',
    () async {
      final cubit = build();
      await cubit.start(defaultAddressId: 'a1');

      await cubit.setMode(FulfillmentMode.pickup);

      expect(cubit.state.selection, isNull);
      expect(cubit.state.canPlace, isFalse);
      await cubit.close();
    },
  );

  test('the order cannot be placed before a destination is chosen', () async {
    final cubit = build();
    await cubit.start();

    await cubit.placeOrder();

    expect(repository.calls, isNot(contains('place:cod')));
    expect(cubit.state.status, CheckoutStatus.ready);
    await cubit.close();
  });

  test('a second tap while placing is ignored', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');
    final gate = Completer<void>();
    repository.placeGate = gate;

    final first = cubit.placeOrder();
    await cubit.placeOrder(); // refused: already placing

    expect(cubit.state.isPlacing, isTrue);
    gate.complete();
    await first;

    expect(
      repository.calls.where((call) => call.startsWith('place')),
      hasLength(1),
    );
    expect(cubit.state.status, CheckoutStatus.placed);
    expect(cubit.state.placedOrder?.id, 'o1');
    await cubit.close();
  });

  test('a rejected order stays on the page with its failure', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');
    repository.placeFailure = const ServerFailure(
      'cart empty',
      statusCode: 400,
    );

    await cubit.placeOrder();

    expect(cubit.state.status, CheckoutStatus.ready);
    expect(cubit.state.isPlacing, isFalse);
    expect(cubit.state.failedAction, CheckoutAction.place);
    await cubit.close();
  });

  test('a scheduled order without a slot cannot be placed', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');

    cubit.setTiming(DeliveryTiming.scheduled);
    expect(cubit.state.canPlace, isFalse);

    cubit.setSlot(repository.days.single.slots.single);
    expect(cubit.state.canPlace, isTrue);

    cubit.setTiming(DeliveryTiming.asap);
    expect(cubit.state.draft.slot, isNull);
    await cubit.close();
  });

  test('the payment method and notes reach the draft', () async {
    final cubit = build();
    await cubit.start(defaultAddressId: 'a1');

    cubit
      ..setPaymentMethod(OrderPaymentMethod.wallet)
      ..setNotes('leave at the door');
    await cubit.placeOrder();

    expect(repository.calls, contains('place:wallet'));
    expect(cubit.state.draft.notes, 'leave at the door');
    await cubit.close();
  });

  test('a cart that already has express opens on the express option', () async {
    final cubit = build();

    // Express is a flag the SERVER keeps on the cart, so a customer who
    // switched it on there is already paying for it when this page opens.
    await cubit.start(expressSelected: true);

    expect(cubit.state.draft.timing, DeliveryTiming.express);
    await cubit.close();
  });

  test('a cart without express opens on ASAP', () async {
    final cubit = build();

    await cubit.start();

    expect(cubit.state.draft.timing, DeliveryTiming.asap);
    await cubit.close();
  });
  test('a second start while the first is loading is ignored', () async {
    final cubit = build();
    final gate = Completer<void>();
    repository.loadGate = gate;

    final first = cubit.start();
    final second = cubit.start(); // a double tap on "retry"
    gate.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.calls.where((call) => call == 'branches'), hasLength(1));
    expect(cubit.state.status, CheckoutStatus.ready);
    await cubit.close();
  });
}
