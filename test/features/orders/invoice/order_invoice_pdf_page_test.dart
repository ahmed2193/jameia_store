// The invoice PDF page over a scripted repository: it opens on the app's
// language with the file named and sized ("1 page · 84 KB") and its pages
// drawn for a look before anything leaves the phone; a language switch
// names and draws the other file; a file that could not be made, or pages
// that could not be drawn, offer a Retry (the actions stay shut without a
// file); a save says "Invoice saved" and stays; Share tells where its
// button is; a failed print is told under the buttons. A phone on its side
// gets the side panel; Arabic at 320 dp and text 130 % has no overflow.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/utils/formatters.dart';
import 'package:hero_mart/src/core/widgets/hero_bottom_bar.dart';
import 'package:hero_mart/src/core/widgets/inline_field_error.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_export_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_preview_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/pages/order_invoice_pdf_page.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/invoice_pdf/invoice_pdf_page_sheet.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/invoice_pdf/invoice_pdf_side_layout.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_invoice_repository.dart';
import 'invoice_test_fixtures.dart';

// The size reads as one left-to-right unit in either language.
final String _size = Formatters.isolate('84 KB');

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

late FakeInvoiceRepository _repository;

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = _en,
  double textScale = 1,
  Size size = const Size(412, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Intl.defaultLocale = locale.languageCode;
  final page = OrderInvoicePdfPage(order: fullInvoiceOrder());
  final router = GoRouter(
    routes: <RouteBase>[GoRoute(path: '/', builder: (_, _) => page)],
  );
  addTearDown(router.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[_en, _ar],
        path: 'assets/i18n',
        fallbackLocale: _en,
        startLocale: locale,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp.router(
            routerConfig: router,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
  // A locale whose file is not cached yet loads on the real event loop.
  for (var i = 0; i < 50 && find.byWidget(page).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await _frames(tester);
}

/// Bounded frames: the fake's file and pages (microtasks), the swaps.
/// Never `pumpAndSettle` — the dots loop.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Takes the page down and lets a snack's timer run out.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

Iterable<InvoicePdfPageSheet> _sheets(WidgetTester tester) =>
    tester.widgetList<InvoicePdfPageSheet>(find.byType(InvoicePdfPageSheet));

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  setUp(() {
    _repository = FakeInvoiceRepository();
    if (sl.isRegistered<InvoiceExportCubit>()) {
      sl.unregister<InvoiceExportCubit>();
    }
    if (sl.isRegistered<InvoicePreviewCubit>()) {
      sl.unregister<InvoicePreviewCubit>();
    }
    sl
      ..registerFactory<InvoiceExportCubit>(
        () => invoiceExportCubit(_repository),
      )
      ..registerFactory<InvoicePreviewCubit>(
        () => invoicePreviewCubit(_repository),
      );
  });

  tearDown(() => Intl.defaultLocale = null);

  testWidgets('opens on the app language with the file and its pages', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Invoice PDF'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('Hero-Invoice-HM-10234-EN.pdf'), findsOneWidget);
    expect(find.text('1 page · $_size'), findsOneWidget);
    expect(_repository.calls, ['build:en', 'render:en']);
    final sheets = _sheets(tester).toList();
    expect(sheets, hasLength(1));
    expect(sheets.single.image, fakePageImage(0));
    expect(find.bySemanticsLabel('Page 1 of 1'), findsOneWidget);
    // The actions sit in the bottom bar, under the pages.
    expect(find.byType(HeroBottomBar), findsOneWidget);
    await _close(tester);
  });

  testWidgets('a switch names and draws the other file', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('العربية'));
    await _frames(tester);

    expect(find.text('Hero-Invoice-HM-10234-AR.pdf'), findsOneWidget);
    expect(_repository.calls, [
      'build:en',
      'render:en',
      'build:ar',
      'render:ar',
    ]);
    expect(_sheets(tester).single.image, fakePageImage(0));
    await _close(tester);
  });

  testWidgets('a file that could not be made: Retry, the actions shut', (
    tester,
  ) async {
    _repository.buildFailure = const CacheFailure('fonts');
    await _pump(tester);

    expect(find.text("Couldn't create the PDF"), findsWidgets);
    expect(find.byType(InvoicePdfPageSheet), findsNothing);
    await tester.tap(find.text('Save to device'));
    await _frames(tester);
    expect(_repository.calls, ['build:en']);

    await tester.tap(find.text('Retry'));
    await _frames(tester);
    expect(find.text('1 page · $_size'), findsOneWidget);
    expect(_sheets(tester).single.image, isNotNull);
    expect(_repository.calls, ['build:en', 'build:en', 'render:en']);
    await _close(tester);
  });

  testWidgets('pages that could not be drawn: Retry draws them again', (
    tester,
  ) async {
    _repository.renderFailure = const CacheFailure('renderer');
    await _pump(tester);

    expect(find.text("Couldn't show the preview"), findsOneWidget);
    // The file itself is fine: the actions take taps.
    await tester.tap(find.text('Print'));
    await _frames(tester);
    expect(_repository.calls, ['build:en', 'render:en', 'print']);

    await tester.tap(find.text('Retry'));
    await _frames(tester);
    expect(find.text("Couldn't show the preview"), findsNothing);
    expect(_sheets(tester).single.image, fakePageImage(0));
    await _close(tester);
  });

  testWidgets('a save says "Invoice saved" and the page stays', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Save to device'));
    await _frames(tester);

    expect(_repository.calls, ['build:en', 'render:en', 'save']);
    expect(find.text('Invoice saved'), findsOneWidget);
    expect(find.text('Invoice PDF'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('Share tells where its button is', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Share'));
    await _frames(tester);

    final origin = _repository.lastOrigin;
    expect(origin, isNotNull);
    expect(origin!.width, greaterThan(0));
    expect(origin.height, greaterThan(0));
    await _close(tester);
  });

  testWidgets('a failed print is told under the buttons', (tester) async {
    _repository.actionFailure = const CacheFailure('no printer');
    await _pump(tester);

    await tester.tap(find.text('Print'));
    await _frames(tester);

    expect(_repository.calls, ['build:en', 'render:en', 'print']);
    expect(find.byType(InlineFieldError), findsOneWidget);
    await _close(tester);
  });

  testWidgets('a phone on its side: the pages beside the panel', (
    tester,
  ) async {
    await _pump(tester, size: const Size(780, 360));

    expect(tester.takeException(), isNull);
    expect(find.byType(InvoicePdfSideLayout), findsOneWidget);
    expect(find.byType(HeroBottomBar), findsNothing);
    expect(find.byType(InvoicePdfPageSheet), findsOneWidget);
    expect(find.text('Save to device'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('Arabic at 320 dp and text scale 1.3: whole, no overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: _ar,
      textScale: 1.3,
      size: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('الفاتورة بصيغة PDF'), findsOneWidget);
    expect(find.text('Hero-Invoice-HM-10234-AR.pdf'), findsOneWidget);
    expect(find.text('صفحة واحدة · $_size'), findsOneWidget);
    expect(_repository.calls, ['build:ar', 'render:ar']);
    await _close(tester);
  });
}
