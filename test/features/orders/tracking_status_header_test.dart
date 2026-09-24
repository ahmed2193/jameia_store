// The tracking header is the one line that tells a customer when to expect
// their order, so it must not describe a pickup as a delivery, and it must not
// hand them the backend's `YYYY-MM-DD`.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/core/data/mappers/order_mapper.dart';
import 'package:jameia_mart/src/core/data/models/order_model.dart';
import 'package:jameia_mart/src/core/domain/entities/order_entity.dart';
import 'package:jameia_mart/src/features/orders/presentation/widgets/tracking/tracking_status_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'order_test_fixtures.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    initializeDateFormatting();
  });

  OrderEntity order({
    String fulfillmentMode = 'delivery',
    Map<String, dynamic>? deliverySlot,
    int? etaMinutes = 45,
  }) => OrderModel.fromJson(
    orderJson(
      fulfillmentMode: fulfillmentMode,
      deliverySlot: deliverySlot,
      etaMinutes: etaMinutes,
    ),
  ).toEntity();

  Future<void> pump(WidgetTester tester, OrderEntity value) async {
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
              home: Scaffold(body: TrackingStatusHeader(order: value)),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a delivery order is told it arrives', (tester) async {
    await pump(tester, order());

    expect(find.textContaining('Arrives in about 45'), findsOneWidget);
  });

  testWidgets('a pickup order is told it is ready, not that it arrives', (
    tester,
  ) async {
    await pump(tester, order(fulfillmentMode: 'pickup'));

    expect(find.textContaining('Ready in about 45'), findsOneWidget);
    expect(find.textContaining('Arrives'), findsNothing);
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
    );

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
    );

    expect(find.textContaining('next-friday'), findsOneWidget);
  });
}
