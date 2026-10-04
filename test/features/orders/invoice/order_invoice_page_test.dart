// The invoice page's PDF wiring over the real DI with fake repositories:
// "Download invoice" waits for the invoice, then opens the PDF page for
// that order (the file and its preview), where a save says "Invoice saved".
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/utils/formatters.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_order_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_export_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_preview_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_invoice_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_invoice_page.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_invoice_pdf_page.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/invoice_pdf/invoice_pdf_page_sheet.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/network_test_fakes.dart';
import '../fake_orders_repository.dart';
import '../order_test_fixtures.dart';
import 'fake_invoice_repository.dart';

/// The fixture order without product pictures (a network image would
/// shimmer forever under the test clock); its load can be held open.
class _OrdersRepository extends FakeOrdersRepository {
  Completer<void>? gate;

  @override
  OrderEntity order({String id = 'o1', String status = 'placed'}) {
    final json = orderJson(id: id, status: status);
    final line = orderLineJson();
    (line['product'] as Map<String, dynamic>)['image'] = '';
    json['lines'] = <Map<String, dynamic>>[line];
    return OrderModel.fromJson(json).toEntity();
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) async {
    final open = gate;
    gate = null;
    await open?.future;
    return super.getOrder(orderId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _OrdersRepository orders;
  late FakeInvoiceRepository invoices;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
    registerFakeNetworkInfo();
    await setupServiceLocator();
  });

  setUp(() {
    orders = _OrdersRepository();
    invoices = FakeInvoiceRepository();
    sl
      ..unregister<OrderInvoiceCubit>()
      ..registerFactory<OrderInvoiceCubit>(
        () => OrderInvoiceCubit(watchOrder: WatchOrderUseCase(orders)),
      )
      ..unregister<InvoiceExportCubit>()
      ..registerFactory<InvoiceExportCubit>(() => invoiceExportCubit(invoices))
      ..unregister<InvoicePreviewCubit>()
      ..registerFactory<InvoicePreviewCubit>(
        () => invoicePreviewCubit(invoices),
      );
  });

  tearDown(() => Intl.defaultLocale = null);

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    Intl.defaultLocale = 'en';
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => const OrderInvoicePage(orderId: 'o1'),
        ),
        GoRoute(
          path: Routes.orderInvoicePdf,
          builder: (_, state) =>
              OrderInvoicePdfPage(order: state.extra! as OrderEntity),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await frames(tester);
  }

  /// Takes the page down and lets the snack's timer run out.
  Future<void> closePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('"Download invoice" waits for the invoice to show', (
    tester,
  ) async {
    final load = Completer<void>();
    orders.gate = load;
    await pumpPage(tester);

    expect(find.text('Download invoice'), findsNothing);

    load.complete();
    await frames(tester);
    expect(find.text('Download invoice'), findsOneWidget);
    await closePage(tester);
  });

  testWidgets('download → the PDF of this order; a save says so', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('Download invoice'));
    await frames(tester);
    expect(find.text('Invoice PDF'), findsOneWidget);
    expect(
      find.text('1 page · ${Formatters.isolate('84 KB')}'),
      findsOneWidget,
    );
    expect(invoices.calls, ['build:en', 'render:en']);
    expect(invoices.lastOrder?.orderNumber, 'JM-1001');
    expect(find.byType(InvoicePdfPageSheet), findsOneWidget);

    await tester.tap(find.text('Save to device'));
    await frames(tester);

    expect(invoices.calls, ['build:en', 'render:en', 'save']);
    expect(find.text('Invoice PDF'), findsOneWidget);
    expect(find.text('Invoice saved'), findsOneWidget);
    await closePage(tester);
  });
}
