import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/get_order_usecase.dart';
import 'package:jameia_mart/src/features/orders/presentation/cubit/order_tracking_cubit.dart';

import 'fake_orders_repository.dart';

import 'package:jameia_mart/src/features/orders/presentation/cubit/order_tracking_state.dart';

void main() {
  late FakeOrdersRepository repository;

  OrderTrackingCubit build() {
    repository = FakeOrdersRepository();
    return OrderTrackingCubit(
      getOrder: GetOrderUseCase(repository),
      cancelOrder: CancelOrderUseCase(repository),
      pollInterval: const Duration(milliseconds: 5),
    );
  }

  Future<void> settle([int turns = 4]) async {
    for (var i = 0; i < turns; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 6));
    }
  }

  test('load shows the order and starts polling', () async {
    final cubit = build();

    await cubit.load('o1');

    expect(cubit.state.status, OrderTrackingStatus.loaded);
    expect(cubit.state.order?.id, 'o1');
    expect(cubit.isPolling, isTrue);

    await settle(2);
    expect(repository.calls.length, greaterThan(1)); // it polled
    await cubit.close();
  });

  test('polling stops on a terminal status', () async {
    final cubit = build();
    repository.detailStatus = 'delivered';

    await cubit.load('o1');

    expect(cubit.state.order?.isTerminal, isTrue);
    expect(cubit.isPolling, isFalse);

    final calls = repository.calls.length;
    await settle(2);
    expect(repository.calls.length, calls);
    await cubit.close();
  });

  test('hiding the page stops the poll, showing it resumes', () async {
    final cubit = build();
    await cubit.load('o1');

    cubit.setVisible(false);
    expect(cubit.isPolling, isFalse);
    final calls = repository.calls.length;
    await settle(2);
    expect(repository.calls.length, calls);

    cubit.setVisible(true);
    expect(cubit.isPolling, isTrue);
    await settle(2);
    expect(repository.calls.length, greaterThan(calls));
    await cubit.close();
  });

  test('closing the page cancels the poll', () async {
    final cubit = build();
    await cubit.load('o1');

    await cubit.close();
    final calls = repository.calls.length;
    await settle(2);

    expect(calls, repository.calls.length);
  });

  test('a load failure with no order shows the error view', () async {
    final cubit = build();
    repository.detailFailure = const NotFoundFailure('gone');

    await cubit.load('o1');

    expect(cubit.state.status, OrderTrackingStatus.error);
    expect(cubit.state.isNotFound, isTrue);
    expect(cubit.isPolling, isFalse);
    await cubit.close();
  });

  test('a poll failure keeps the order on screen', () async {
    final cubit = build();
    await cubit.load('o1');
    repository.detailFailure = const NetworkFailure();

    await cubit.refresh();

    expect(cubit.state.status, OrderTrackingStatus.loaded);
    expect(cubit.state.order, isNotNull);
    expect(cubit.state.failure, isA<NetworkFailure>());
    await cubit.close();
  });

  test('cancel runs once and stops the poll on the cancelled order', () async {
    final cubit = build();
    await cubit.load('o1');

    final cancelled = await cubit.cancel(reason: CancelOrderReason.tooSlow);

    expect(cancelled, isTrue);
    expect(cubit.state.cancelled, isTrue);
    expect(cubit.state.order?.status, OrderStatus.cancelled);
    expect(cubit.isPolling, isFalse);
    await cubit.close();
  });

  test('a cancel failure keeps the order cancellable', () async {
    final cubit = build();
    await cubit.load('o1');
    repository.cancelFailure = const ServerFailure('too late', statusCode: 400);

    final cancelled = await cubit.cancel(reason: CancelOrderReason.other);

    expect(cancelled, isFalse);
    expect(cubit.state.isCancelling, isFalse);
    expect(cubit.state.canCancel, isTrue);
    expect(cubit.state.failedAction, OrderTrackingAction.cancel);
    await cubit.close();
  });

  test('a failed background poll stays silent and keeps polling', () async {
    final cubit = build();
    await cubit.load('o1');
    final before = cubit.state;
    repository.detailFailure = const NetworkFailure();

    // Wait for the poll to have actually gone out and come back failed,
    // instead of hoping a fixed delay lands between two timers.
    while (repository.calls.where((call) => call == 'getOrder:o1').length < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, OrderTrackingStatus.loaded);
    expect(cubit.state.order, before.order);
    expect(
      cubit.state.failure,
      isNull,
      reason: 'nobody asked for it: no toast every interval',
    );
    expect(cubit.isPolling, isTrue);
    await cubit.close();
  });
}
