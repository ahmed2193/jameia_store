// The invoice page and its PDF sheet on the app's real fonts, in English and
// Arabic, on phones (320 / 360 / 412 dp, text scale 1 and 1.3), a tablet
// (840 dp) and a phone on its side (780 × 360 dp): nothing overflows.
// Set INVOICE_SHOTS_OUT=<dir> to keep a PNG of every screen for a look, and
// INVOICE_PREVIEW_PNG_DIR=<dir> (full-en-1.png / full-ar-1.png, the render
// test's PDFs through pdftoppm) to show real pages in the PDF preview.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_order_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_export_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_preview_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_invoice_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_invoice_page.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_invoice_pdf_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/network_test_fakes.dart';
import '../fake_orders_repository.dart';
import 'fake_invoice_repository.dart';
import 'invoice_test_fixtures.dart';

const Map<String, List<String>> _fonts = {
  'NotoSans': [
    'NotoSans-Regular.ttf',
    'NotoSans-Medium.ttf',
    'NotoSans-SemiBold.ttf',
    'NotoSans-Bold.ttf',
  ],
  'NotoSansArabicUI': [
    'NotoSansArabicUI-Regular.ttf',
    'NotoSansArabicUI-Medium.ttf',
    'NotoSansArabicUI-SemiBold.ttf',
    'NotoSansArabicUI-Bold.ttf',
  ],
  'HeroDigits': [
    'HeroDigits-Regular.ttf',
    'HeroDigits-Medium.ttf',
    'HeroDigits-Bold.ttf',
  ],
  'HeroIcons': ['hero_icons.ttf'],
};

/// The invoice of a real-looking order: Latin product names and sizes even
/// in Arabic (as the store sends them), an Arabic-named line, a replaced
/// and an unavailable line, a free offer line, every discount.
OrderEntity _order() => fullInvoiceOrder(
  status: OrderStatus.placed,
  paymentStatus: OrderPaymentStatus.pending,
  lines: [
    invoiceLine(
      'l1',
      nameEn: 'KDD Full Cream Milk',
      nameAr: 'KDD Full Cream Milk',
      variantEn: '2 Liter',
      variantAr: '2 Liter',
      quantity: 3,
      unitPriceFils: 899,
    ),
    invoiceLine('l2', quantity: 2),
    invoiceLine(
      'l3',
      nameEn: 'Nadec Greek yoghurt 170g',
      nameAr: 'زبادي يوناني نادك ١٧٠ جم',
      quantity: 3,
      unitPriceFils: 350,
    ),
    invoiceLine(
      'l4',
      nameEn: 'KDD orange juice 1L',
      nameAr: 'عصير برتقال كي دي دي ١ لتر',
      unitPriceFils: 750,
    ),
    invoiceLine(
      'l5',
      nameEn: 'Basmati Rice 5kg (Premium extra long grain, family pack)',
      nameAr: 'Basmati Rice 5kg (Premium extra long grain, family pack)',
      quantity: 7,
      unitPriceFils: 3250,
    ),
  ],
);

class _Orders extends FakeOrdersRepository {
  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) async =>
      Right(_order());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['INVOICE_SHOTS_OUT'];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
    for (final entry in _fonts.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
    registerFakeNetworkInfo();
    await setupServiceLocator();
    final orders = _Orders();
    final invoices = FakeInvoiceRepository();
    final pages = Platform.environment['INVOICE_PREVIEW_PNG_DIR'];
    if (pages != null) {
      invoices.pagePngOf = (language) =>
          File('$pages/full-${language.code}-1.png').readAsBytesSync();
    }
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
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
    if (out == null) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File('$out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  // Most phones are made tall enough to show the whole receipt in one shot;
  // one has a real phone's height, for the PDF page's bars around its pages.
  const tall = 2000.0;
  final screens = <(Size, double)>[
    for (final width in [320.0, 360.0, 412.0])
      for (final scale in [1.0, 1.3]) (Size(width, tall), scale),
    (Size(360, 740), 1.3),
    (Size(840, 1600), 1),
    (Size(780, 360), 1),
  ];
  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final (size, scale) in screens) {
      {
        final width = size.width;
        final name =
            'invoice-${locale.languageCode}-${width.toInt()}'
            '${size.height < width ? '-landscape' : ''}'
            '${size.height < width || size.height == tall ? '' : '-real'}'
            '${scale == 1 ? '' : '-x$scale'}';
        testWidgets(name, (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          Intl.defaultLocale = locale.languageCode;
          final key = GlobalKey();
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
              RepaintBoundary(
                key: key,
                child: EasyLocalization(
                  supportedLocales: const [Locale('en'), Locale('ar')],
                  path: 'assets/i18n',
                  fallbackLocale: const Locale('en'),
                  startLocale: locale,
                  saveLocale: false,
                  child: Builder(
                    builder: (context) => MaterialApp.router(
                      theme: AppTheme.light,
                      routerConfig: router,
                      locale: context.locale,
                      supportedLocales: context.supportedLocales,
                      localizationsDelegates: context.localizationDelegates,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaler: TextScaler.linear(scale)),
                        child: child!,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await frames(tester);
          expect(tester.takeException(), isNull);
          await shoot(tester, key, name);

          // The facts sit two to a row only where two fit: 360 dp and up
          // at the normal text size, one under the other otherwise.
          final ar = locale.languageCode == 'ar';
          final number = tester.getTopLeft(
            find.text(ar ? 'رقم الطلب' : 'Order number'),
          );
          final type = tester.getTopLeft(
            find.text(ar ? 'نوع الطلب' : 'Order type'),
          );
          expect(number.dy == type.dy, scale == 1 && width >= 360);

          final download = find.text(
            ar ? 'تنزيل الفاتورة' : 'Download invoice',
          );
          await tester.tap(download);
          await frames(tester);
          // The page pictures decode on the real event loop.
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
          );
          await frames(tester);
          expect(tester.takeException(), isNull);
          await shoot(tester, key, '$name-pdf');

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        });
      }
    }
  }
}
