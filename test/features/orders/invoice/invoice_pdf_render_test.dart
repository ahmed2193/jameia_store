// The invoice PDF end to end on the real bundle (i18n strings, Noto fonts,
// logo) and the real layout on its background isolate: both languages, one
// page and many, every optional part. Set INVOICE_PDF_OUT=<dir> to keep the
// files for a look (pdftoppm renders them to PNG).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_assets_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_file_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_pdf_data_source.dart';
import 'package:hero_mart/src/features/orders/data/repositories/invoice_repository_impl.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_document.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'invoice_test_fixtures.dart';

class _NoFiles implements InvoiceFileDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('no system screens in a layout test');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final repository = InvoiceRepositoryImpl(
    assets: InvoiceAssetsDataSourceImpl(DiskAssetBundle()),
    pdf: const InvoicePdfDataSourceImpl(),
    files: _NoFiles(),
    clock: () => DateTime(2026, 10, 1, 21, 40),
  );
  final out = Platform.environment['INVOICE_PDF_OUT'];

  Future<InvoiceDocument> build(
    String name,
    InvoiceLanguage language, {
    OrderStatus status = OrderStatus.delivered,
    OrderPaymentStatus paymentStatus = OrderPaymentStatus.paid,
    int lines = 0,
  }) async {
    final result = await repository.buildPdf(
      fullInvoiceOrder(
        status: status,
        paymentStatus: paymentStatus,
        lines: lines == 0 ? null : manyInvoiceLines(lines),
      ),
      language,
    );
    final document = result.fold(
      (failure) => fail('no PDF: $failure'),
      (document) => document,
    );
    if (out != null) {
      File('$out/$name-${language.code}.pdf')
        ..createSync(recursive: true)
        ..writeAsBytesSync(document.bytes);
    }
    return document;
  }

  for (final language in InvoiceLanguage.values) {
    group(language.name, () {
      test('a full order fits one A4 page, a real PDF file', () async {
        final document = await build('full', language);

        expect(ascii.decode(document.bytes.sublist(0, 5)), '%PDF-');
        expect(document.pageCount, 1);
        expect(
          document.fileName,
          'Hero-Invoice-HM-10234-${language.code.toUpperCase()}.pdf',
        );
        expect(document.language, language);
        // Fonts are subset: the file stays far under the 1.5 MB of fonts.
        expect(document.sizeInBytes, lessThan(400 * 1024));
      });

      test('a long order runs on to more pages', () async {
        final document = await build('long', language, lines: 70);

        expect(document.pageCount, greaterThan(1));
      });

      test('a cancelled, unpaid order still lays out', () async {
        final document = await build(
          'cancelled',
          language,
          status: OrderStatus.cancelled,
          paymentStatus: OrderPaymentStatus.pending,
        );

        expect(document.pageCount, 1);
      });
    });
  }

  test('a missing language file throws CacheException', () async {
    await expectLater(
      InvoiceAssetsDataSourceImpl(DiskAssetBundle()).labels('xx'),
      throwsA(isA<CacheException>()),
    );
  });
}
