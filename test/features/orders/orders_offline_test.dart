// Orders offline: the first page and each order opened are kept on the
// device for the signed-in customer (never for a guest); a cancel reply
// replaces the order's copy; the list, the tracking page and the invoice
// paint the saved copy, mark it stale and ask again once on reconnect; the
// tracking poll is not scheduled offline and runs at once on reconnect;
// "Last known status" sits under a status that is not live; a next page
// that failed waits for the connection.
import 'package:bloc_test/bloc_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/core/data/datasources/cache_slots.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/data/models/remote_payload.dart';
import 'package:hero_mart/src/core/domain/entities/data_freshness.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';
import 'package:hero_mart/src/core/storage/cache_namespace.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/features/orders/data/datasources/orders_cache_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:hero_mart/src/features/orders/data/models/orders_page_model.dart';
import 'package:hero_mart/src/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:hero_mart/src/features/orders/domain/entities/cancel_order_request.dart';
import 'package:hero_mart/src/features/orders/domain/entities/orders_page.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_order_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/submit_product_review_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_order_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_orders_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_invoice_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_review_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_tracking_state.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_last_known_note.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';
import 'fake_orders_repository.dart';
import 'order_test_fixtures.dart';

/// The order routes answering the fixtures; [error] fails the reads.
class _ScriptedRemote implements OrdersRemoteDataSource {
  Object? error;
  int listReads = 0;
  int orderReads = 0;

  @override
  Future<RemotePayload<OrdersPageModel>> getOrders({
    required int page,
    required int limit,
  }) async {
    listReads++;
    final current = error;
    if (current != null) throw current;
    final raw = ordersPageJson(page: page);
    return RemotePayload(
      OrdersPageModel.fromJson(raw, requestedPage: page),
      raw,
    );
  }

  @override
  Future<RemotePayload<OrderModel>> getOrder(String orderId) async {
    orderReads++;
    final current = error;
    if (current != null) throw current;
    final raw = orderJson(id: orderId);
    return RemotePayload(OrderModel.fromJson(raw), raw);
  }

  @override
  Future<RemotePayload<OrderModel>> cancelOrder(
    String orderId,
    Map<String, dynamic> body,
  ) async {
    final raw = orderJson(id: orderId, status: 'cancelled');
    return RemotePayload(OrderModel.fromJson(raw), raw);
  }

  @override
  Future<void> submitReview(Map<String, dynamic> body) async {}
}

class _MockTrackingCubit extends MockCubit<OrderTrackingState>
    implements OrderTrackingCubit {}

/// A repository over an in-memory device store, for [owner].
OrdersRepositoryImpl _repository(
  _ScriptedRemote remote,
  InMemoryJsonCacheStore store,
  CacheOwner owner,
) => OrdersRepositoryImpl(
  remote,
  cache: OrdersCacheDataSourceImpl(
    CacheSlots(store: store, owner: owner, locale: FakeLocaleProvider('en')),
  ),
);

CacheOwner _customer() => CacheOwner()..signedIn('c1');

void main() {
  group('the device copy', () {
    test('orders are the customer\'s own: no slot for a guest', () {
      final guest = OrdersCacheDataSourceImpl(
        CacheSlots(
          store: InMemoryJsonCacheStore(),
          owner: CacheOwner()..signedOut(),
          locale: FakeLocaleProvider('en'),
        ),
      );

      expect(guest.firstPage(limit: 20), isNull);
      expect(guest.order('o1'), isNull);
      expect(
        OrdersCacheDataSourceImpl.listNamespace.scope,
        CacheScope.customer,
      );
      expect(
        OrdersCacheDataSourceImpl.detailNamespace.freshFor,
        Duration.zero,
        reason: 'an order moves: its copy is never fresh',
      );
    });

    test('the first page and an order paint from it', () async {
      final remote = _ScriptedRemote();
      final repository = _repository(
        remote,
        InMemoryJsonCacheStore(),
        _customer(),
      );
      await repository.watchFirstPage(limit: 20).drain<void>();
      await repository.watchOrder('o1').drain<void>();
      await pumpEventQueue();
      remote.error = const NoInternetConnectionException();

      final list = await repository.watchFirstPage(limit: 20).toList();

      expect(list.single.isFromCache, isTrue);
      expect(list.single.data.orders.single.id, 'o1');
      expect(remote.listReads, 1, reason: 'a fresh copy ends the read');
      await expectLater(
        repository.watchOrder('o1'),
        emitsInOrder(<Matcher>[
          isA<DataSnapshot<OrderEntity>>().having(
            (snapshot) => snapshot.isFromCache,
            'isFromCache',
            isTrue,
          ),
          emitsError(isA<NetworkFailure>()),
        ]),
      );
      expect(remote.orderReads, 2, reason: 'the order is always asked');
    });

    test('a cancel reply replaces the order\'s copy', () async {
      final remote = _ScriptedRemote();
      final repository = _repository(
        remote,
        InMemoryJsonCacheStore(),
        _customer(),
      );
      await repository.watchOrder('o1').drain<void>();
      await repository.cancelOrder(
        const CancelOrderRequest(
          orderId: 'o1',
          reason: CancelOrderReason.changedMind,
        ),
      );
      await pumpEventQueue();
      remote.error = const NoInternetConnectionException();

      await expectLater(
        repository.watchOrder('o1'),
        emitsInOrder(<Matcher>[
          isA<DataSnapshot<OrderEntity>>().having(
            (snapshot) => snapshot.data.status,
            'status',
            OrderStatus.cancelled,
          ),
          emitsError(isA<NetworkFailure>()),
        ]),
      );
    });

    test(
      'a reply for a customer who signed out meanwhile is dropped',
      () async {
        final remote = _ScriptedRemote();
        final store = InMemoryJsonCacheStore();
        final owner = _customer();
        final repository = _repository(remote, store, owner);

        final read = repository.watchFirstPage(limit: 20).drain<void>();
        owner.signedOut();
        await read;
        await pumpEventQueue();

        expect(store.writes, 0);
      },
    );
  });

  group('OrdersCubit', () {
    late FakeOrdersRepository repository;

    OrdersCubit build() => OrdersCubit(
      watchFirstPage: WatchOrdersUseCase(repository),
      getOrders: GetOrdersUseCase(repository),
      getOrder: GetOrderUseCase(repository),
      cancelOrder: CancelOrderUseCase(repository),
    );

    OrdersPage saved() =>
        OrdersPage(orders: [repository.order(id: 'saved')], page: 1);

    setUp(() => repository = FakeOrdersRepository());

    test('offline with a saved first page: the list, marked stale', () async {
      repository
        ..savedFirstPage = saved()
        ..listFailure = const NetworkFailure();
      final cubit = build();

      await cubit.load();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.feed.orders.single.id, 'saved');
      expect(cubit.state.load.freshness.fromCache, isTrue);
      expect(cubit.state.load.freshness.refreshFailed, isTrue);
      expect(cubit.state.load.failure, isA<NetworkFailure>());
      await cubit.close();
    });

    test('reconnect refreshes a saved list once; a fresh one stays', () async {
      final cubit = build();
      await cubit.load();
      await cubit.onReconnected();
      expect(repository.forcedReads, [false], reason: 'fresh: no request');

      repository
        ..savedFirstPage = saved()
        ..listFailure = const NetworkFailure();
      await cubit.load();
      expect(cubit.state.load.freshness.isStale, isTrue);

      await Future.wait([cubit.onReconnected(), cubit.onReconnected()]);

      expect(repository.forcedReads, [false, false, true]);
      expect(cubit.state.feed.orders.single.id, 'o1');
      expect(cubit.state.load.freshness.isStale, isFalse);
      await cubit.close();
    });

    test('a next page that failed waits for the connection', () async {
      repository.pages = 3;
      final cubit = build();
      await cubit.load();
      int secondPages() =>
          repository.calls.where((call) => call == 'getOrders:2').length;

      repository.listFailure = const NetworkFailure();
      await cubit.loadMore();
      expect(cubit.state.loadMoreFailed, isTrue);
      await cubit.loadMore(); // a scroll after the failure
      expect(secondPages(), 1, reason: 'no request on every scroll');

      await cubit.onReconnected();

      expect(secondPages(), 2);
      expect(cubit.state.loadMoreFailed, isFalse);
      expect(
        [for (final order in cubit.state.feed.orders) order.id],
        ['o1', 'o2'],
      );
      await cubit.close();
    });

    test('nothing saved: the page keeps its reason while it retries', () async {
      repository.listFailure = const NetworkFailure();
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, LoadPhase.error);
      expect(cubit.state.loadFailure, isA<NetworkFailure>());

      final retry = cubit.refresh(); // flags the refresh first
      expect(cubit.state.isRefreshing, isTrue);
      expect(cubit.state.loadFailure, isA<NetworkFailure>());
      await retry;

      expect(cubit.state.status, LoadPhase.loaded);
      await cubit.close();
    });
  });

  group('OrderTrackingCubit', () {
    late FakeOrdersRepository repository;

    OrderTrackingCubit build() => OrderTrackingCubit(
      watchOrder: WatchOrderUseCase(repository),
      cancelOrder: CancelOrderUseCase(repository),
      pollInterval: const Duration(milliseconds: 5),
    );

    int reads() =>
        repository.calls.where((call) => call == 'getOrder:o1').length;

    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 6));
      }
    }

    setUp(() => repository = FakeOrdersRepository());

    test('offline: no poll; the reconnect polls once at once', () async {
      final cubit = build();
      await cubit.load('o1');

      cubit.setOffline(true);
      expect(cubit.isPolling, isFalse);
      final before = reads();
      await settle();
      expect(reads(), before, reason: 'no request while offline');

      cubit.setOffline(false);
      expect(cubit.isPolling, isTrue);
      final reconnect = cubit.onReconnected();
      expect(reads(), before + 1, reason: 'the poll went out at once');
      await reconnect;
      await cubit.close();
    });

    test('the saved order first; a failed poll makes it last known', () async {
      repository.savedOrder = repository.order(status: 'confirmed');
      final cubit = build();
      final states = <OrderTrackingState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('o1');
      expect(
        states.firstWhere((state) => state.order != null).freshness.fromCache,
        isTrue,
      );
      expect(cubit.state.load.freshness.fromCache, isFalse);

      repository.detailFailure = const NetworkFailure();
      while (reads() < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.load.freshness.refreshFailed, isTrue);
      expect(cubit.state.load.failure, isNull, reason: 'a poll stays silent');
      await subscription.cancel();
      await cubit.close();
    });

    test('reconnect reloads a page that could not load', () async {
      repository.detailFailure = const NetworkFailure();
      final cubit = build();
      await cubit.load('o1');
      expect(cubit.state.loadFailure, isA<NetworkFailure>());

      await cubit.onReconnected();

      expect(cubit.state.status, LoadPhase.loaded);
      await cubit.close();
    });

    test('a finished order fresh from the server needs nothing', () async {
      repository.detailStatus = 'delivered';
      final cubit = build();
      await cubit.load('o1');
      final before = reads();

      await cubit.onReconnected();

      expect(reads(), before);
      await cubit.close();
    });
  });

  group('invoice and review', () {
    test('the saved invoice shows offline; reconnect refreshes it', () async {
      final repository = FakeOrdersRepository();
      repository
        ..savedOrder = repository.order()
        ..detailFailure = const NetworkFailure();
      final cubit = OrderInvoiceCubit(
        watchOrder: WatchOrderUseCase(repository),
      );

      await cubit.load('o1');
      expect(cubit.state.load.phase, LoadPhase.loaded);
      expect(cubit.state.load.freshness.isStale, isTrue);
      expect(cubit.state.load.failure, isA<NetworkFailure>());

      await cubit.onReconnected();
      expect(cubit.state.load.freshness.isStale, isFalse);
      expect(repository.forcedReads, [false, true]);
      await cubit.close();
    });

    test(
      'the saved order opens the review; a failed submit keeps the stars',
      () async {
        final repository = FakeOrdersRepository();
        repository
          ..savedOrder = repository.order(status: 'delivered')
          ..detailFailure = const NetworkFailure()
          ..reviewFailure = const NetworkFailure();
        final cubit = OrderReviewCubit(
          watchOrder: WatchOrderUseCase(repository),
          submitReview: SubmitProductReviewUseCase(repository),
        );

        await cubit.load('o1');
        expect(cubit.state.status, LoadPhase.loaded);
        cubit.rate('p1', 4);

        expect(await cubit.submit(), isFalse);
        expect(cubit.state.load.failedOn, FailedCall.action);
        expect(cubit.state.load.failure, isA<NetworkFailure>());
        expect(cubit.state.canSubmit, isTrue, reason: 'the draft is kept');
        await cubit.close();
      },
    );
  });

  group('TrackingLastKnownNote', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late _MockTrackingCubit cubit;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      await initializeDateFormatting();
    });

    setUp(() => cubit = _MockTrackingCubit());

    Future<void> pump(
      WidgetTester tester, {
      required OrderEntity order,
      required DataFreshness freshness,
      required bool offline,
    }) {
      whenListen(
        cubit,
        const Stream<OrderTrackingState>.empty(),
        initialState: OrderTrackingState(
          load: ScreenLoad(phase: LoadPhase.loaded, freshness: freshness),
          order: order,
        ),
      );
      return tester
          .runAsync(() async {
            await tester.pumpWidget(
              EasyLocalization(
                supportedLocales: const <Locale>[Locale('en')],
                path: 'assets/i18n',
                fallbackLocale: const Locale('en'),
                child: ConnectivityScope(
                  isOffline: offline,
                  reconnectEpoch: 0,
                  onNudge: () {},
                  child: BlocProvider<OrderTrackingCubit>.value(
                    value: cubit,
                    child: Builder(
                      builder: (context) => MaterialApp(
                        locale: context.locale,
                        supportedLocales: context.supportedLocales,
                        localizationsDelegates: context.localizationDelegates,
                        home: Scaffold(
                          body: TrackingLastKnownNote(order: order),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await Future<void>.delayed(Duration.zero);
          })
          .then((_) => tester.pumpAndSettle());
    }

    final live = DataFreshness(fetchedAt: DateTime.now());
    final order = FakeOrdersRepository().order(status: 'confirmed');

    testWidgets('offline: the status is the last known one', (tester) async {
      await pump(tester, order: order, freshness: live, offline: true);

      expect(find.textContaining('Last known status'), findsOneWidget);
    });

    testWidgets('a failed check says so online too', (tester) async {
      await pump(
        tester,
        order: order,
        freshness: live.failed(),
        offline: false,
      );

      expect(find.textContaining('Last known status'), findsOneWidget);
    });

    testWidgets('live, or a finished order: nothing', (tester) async {
      await pump(tester, order: order, freshness: live, offline: false);
      expect(find.textContaining('Last known status'), findsNothing);

      await pump(
        tester,
        order: FakeOrdersRepository().order(status: 'delivered'),
        freshness: live,
        offline: true,
      );
      expect(find.textContaining('Last known status'), findsNothing);
    });
  });
}
