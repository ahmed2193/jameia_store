import 'dart:developer';
import 'dart:isolate';

import '../../../../core/error/exceptions.dart';
import '../models/invoice_pdf_assets_model.dart';
import '../models/invoice_pdf_file_model.dart';
import '../models/invoice_pdf_model.dart';
import 'invoice_pdf/invoice_pdf_document.dart';

/// Turns a written-out invoice into a PDF file.
abstract class InvoicePdfDataSource {
  /// Lays [invoice] out as A4 pages with [assets] (fonts, logo). Throws
  /// [CacheException].
  Future<InvoicePdfFileModel> render(
    InvoicePdfModel invoice,
    InvoicePdfAssetsModel assets,
  );
}

class InvoicePdfDataSourceImpl implements InvoicePdfDataSource {
  const InvoicePdfDataSourceImpl();

  @override
  Future<InvoicePdfFileModel> render(
    InvoicePdfModel invoice,
    InvoicePdfAssetsModel assets,
  ) async {
    try {
      // Off the UI isolate: Arabic shaping, font subsetting and compression
      // take a few hundred milliseconds on a mid phone, and the sheet that
      // asked for the file keeps moving meanwhile.
      return await Isolate.run(
        () => InvoicePdfDocument.layOut(invoice, assets),
        debugName: 'invoice-pdf',
      );
    } on Object catch (error, stackTrace) {
      log(
        'Invoice PDF layout failed',
        name: 'InvoicePdf',
        error: error,
        stackTrace: stackTrace,
      );
      throw CacheException('invoice pdf: $error');
    }
  }
}
