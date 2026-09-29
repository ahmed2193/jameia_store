// The status panel is the one place that tells a customer when to expect
// their order, so it counts down honestly (the server's estimate from when
// the order was placed, rounded up the checkout's way), says so when that
// time has passed, never describes a pickup as a delivery, and never hands
// them the backend's `YYYY-MM-DD`.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/motion/second_clock_scope.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_order_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_status_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_orders_repository.dart';
import 'order_test_fixtures.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  /// The fixture's order was placed at 09:00 UTC with a 45 min estimate.
  final placed = DateTime.utc(2026, 9, 21, 9);

  OrderEntity order({
    String status = 'picking',
    String fulfillmentMode = 'delivery',
    Map<String, dynamic>? deliverySlot,
    int? etaMinutes = 45,
  }) => OrderModel.fromJson(
    orderJson(
      status: status,
      fulfillmentMode: fulfillmentMode,
      deliverySlot: deliverySlot,
      etaMinutes: etaMinutes,
    ),
  ).toEntity();

  /// The panel under a minute clock that reads [now].
  Future<void> pump(
    WidgetTester tester,
    OrderEntity value,
    DateTime Function() now,
  ) async {
    final cubit = OrderTrackingCubit(
      watchOrder: WatchOrderUseCase(FakeOrdersRepository()),
      cancelOrder: CancelOrderUseCase(FakeOrdersRepository()),
    );
    addTearDown(cubit.close);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: BlocProvider<OrderTrackingCubit>.value(
                value: cubit,
                child: Scaffold(
                  body: SecondClockScope(
                    clock: now,
                    period: const Duration(minutes: 1),
                    child: TrackingStatusHero(order: value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a delivery order counts down to its arrival', (tester) async {
    var now = placed.add(const Duration(minutes: 10));
    await pump(tester, order(), () => now);

    expect(find.text('Arriving in'), findsOneWidget);
    expect(find.text('35 min'), findsOneWidget);
    expect(find.textContaining('Estimated at'), findsOneWidget);

    // A minute later the value flips on its own.
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('34 min'), findsOneWidget);
    expect(find.text('35 min'), findsNothing);
  });

  testWidgets('a pickup order is told it is ready, not that it arrives', (
    tester,
  ) async {
    await pump(
      tester,
      order(fulfillmentMode: 'pickup'),
      () => placed.add(const Duration(minutes: 10)),
    );

    expect(find.text('Ready in'), findsOneWidget);
    expect(find.text('35 min'), findsOneWidget);
    expect(find.textContaining('Arriving'), findsNothing);
  });

  testWidgets('past the estimate it says it is late, never a countdown', (
    tester,
  ) async {
    await pump(
      tester,
      order(status: 'out_for_delivery'),
      () => placed.add(const Duration(hours: 2)),
    );

    expect(find.textContaining('Running a little late'), findsOneWidget);
    expect(find.textContaining(' min'), findsNothing);
    // The stage leads instead.
    expect(find.text('On the way'), findsOneWidget);
  });

  testWidgets('a booked window shows the day as the customer reads dates', (
    tester,
  ) async {
    await pump(
      tester,
      order(
        deliverySlot: const <String, dynamic>{
          'templateId': 't_1_0',
          'date': '2026-09-22',
          'start': '10:00',
          'end': '12:00',
        },
      ),
      () => placed,
    );

    expect(find.text('Scheduled delivery'), findsOneWidget);
    expect(find.textContaining('Tue, Sep 22, 2026'), findsOneWidget);
    expect(find.textContaining('2026-09-22'), findsNothing);
    // The window itself still reads left to right.
    expect(find.textContaining('10:00'), findsOneWidget);
  });

  testWidgets('a wire day the backend never parsed falls back to its text', (
    tester,
  ) async {
    await pump(
      tester,
      order(
        deliverySlot: const <String, dynamic>{
          'templateId': 't_1_0',
          'date': 'next-friday',
          'start': '10:00',
          'end': '12:00',
        },
      ),
      () => placed,
    );

    expect(find.textContaining('next-friday'), findsOneWidget);
  });
}
