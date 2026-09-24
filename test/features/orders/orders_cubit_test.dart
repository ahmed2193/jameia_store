import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/order_status.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/cancel_order_request.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/get_order_usecase.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:jameia_mart/src/features/orders/presentation/cubit/orders_cubit.dart';

import 'fake_orders_repository.dart';

import 'package:jameia_mart/src/features/orders/presentation/cubit/orders_state.dart';

void main() {
  late FakeOrdersRepository repository;

  OrdersCubit build() {
    repository = FakeOrdersRepository();
    return OrdersCubit(
      getOrders: GetOrdersUseCase(repository),
      getOrder: GetOrderUseCase(repository),
      cancelOrder: CancelOrderUseCase(repository),
    );
  }

  test('load fills the feed and buckets it by status group', () async {
    final cubit = build();

    await cubit.load();

    expect(cubit.state.status, OrdersStatus.loaded);
    expect(cubit.state.feed.orders, hasLength(1));
    expect(cubit.state.feed.byGroup(OrderStatusGroup.inProgress), hasLength(1));
    expect(cubit.state.feed.byGroup(OrderStatusGroup.completed), isEmpty);
    await cubit.close();
  });

  test('a load failure with an empty feed shows the error view', () async {
    final cubit = build();
    repository.listFailure = const NetworkFailure();

    await cubit.load();

    expect(cubit.state.status, OrdersStatus.error);
    expect(cubit.state.loadFailure, isA<NetworkFailure>());
    await cubit.close();
  });

  test('a refresh failure keeps the rows already loaded', () async {
    final cubit = build();
    await cubit.load();
    repository.listFailure = const TimeoutFailure();

    await cubit.refresh();

    expect(cubit.state.status, OrdersStatus.loaded);
    expect(cubit.state.feed.orders, hasLength(1));
    expect(cubit.state.failure, isA<TimeoutFailure>());
    await cubit.close();
  });

  test('loadMore appends the next page and stops at the end', () async {
    final cubit = build();
    repository.pages = 2;
    await cubit.load();

    await cubit.loadMore();

    expect(cubit.state.feed.orders, hasLength(2));
    expect(cubit.state.feed.hasMore, isFalse);

    repository.calls.clear();
    await cubit.loadMore(); // nothing left
    expect(repository.calls, isEmpty);
    await cubit.close();
  });

  test('a page that lands after a refresh is dropped', () async {
    final cubit = build();
    repository.pages = 3;
    await cubit.load();

    final gate = Completer<void>();
    repository.listGate = gate;
    final stale = cubit.loadMore(); // page 2, held open
    await Future<void>.delayed(Duration.zero);
    await cubit.refresh(); // replaces the feed
    gate.complete();
    await stale;

    expect(cubit.state.feed.orders, hasLength(1));
    expect(cubit.state.feed.page, 1);
    expect(cubit.state.isLoadingMore, isFalse);
    await cubit.close();
  });

  test('a second cancel is refused while one is in flight', () async {
    final cubit = build();
    await cubit.load();
    final gate = Completer<void>();
    repository.cancelGate = gate;

    const request = CancelOrderRequest(
      orderId: 'o1',
      reason: CancelOrderReason.tooSlow,
    );
    final first = cubit.cancel(request);
    final second = await cubit.cancel(request);

    expect(second, isFalse);
    expect(cubit.state.isCancelling('o1'), isTrue);
    gate.complete();
    expect(await first, isTrue);
    expect(cubit.state.cancellingId, isNull);
    expect(
      repository.calls.where((call) => call.startsWith('cancel')),
      hasLength(1),
    );
    await cubit.close();
  });

  test('a cancelled order moves to the cancelled bucket in place', () async {
    final cubit = build();
    await cubit.load();

    await cubit.cancel(
      const CancelOrderRequest(
        orderId: 'o1',
        reason: CancelOrderReason.changedMind,
      ),
    );

    expect(cubit.state.feed.orders, hasLength(1));
    expect(cubit.state.feed.byGroup(OrderStatusGroup.cancelled), hasLength(1));
    expect(cubit.state.feed.byGroup(OrderStatusGroup.inProgress), isEmpty);
    await cubit.close();
  });

  test('a cancel failure keeps the order and reports it', () async {
    final cubit = build();
    await cubit.load();
    repository.cancelFailure = const ServerFailure('too late', statusCode: 400);

    final cancelled = await cubit.cancel(
      const CancelOrderRequest(orderId: 'o1', reason: CancelOrderReason.other),
    );

    expect(cancelled, isFalse);
    expect(cubit.state.failedAction, OrdersAction.cancel);
    expect(cubit.state.feed.byGroup(OrderStatusGroup.inProgress), hasLength(1));
    await cubit.close();
  });

  test(
    'refreshOrder replaces one row after the tracking page closes',
    () async {
      final cubit = build();
      await cubit.load();
      repository.detailStatus = 'delivered';

      await cubit.refreshOrder('o1');

      expect(cubit.state.feed.orders, hasLength(1));
      expect(
        cubit.state.feed.byGroup(OrderStatusGroup.completed),
        hasLength(1),
      );
      await cubit.close();
    },
  );

  test('a note over the API limit never reaches the repository', () async {
    final cubit = build();
    await cubit.load();
    repository.calls.clear();

    final cancelled = await cubit.cancel(
      CancelOrderRequest(
        orderId: 'o1',
        reason: CancelOrderReason.other,
        note: 'x' * (CancelOrderRequest.maxNoteLength + 1),
      ),
    );

    expect(cancelled, isFalse);
    expect(repository.calls, isEmpty);
    expect(cubit.state.failure, isA<ValidationFailure>());
    await cubit.close();
  });
}
