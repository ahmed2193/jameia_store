import 'dart:ui' show Rect;

import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/invoice_document.dart';
import '../../domain/entities/invoice_language.dart';
import '../../domain/entities/invoice_page_image.dart';
import '../../domain/entities/invoice_share_origin.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_assets_data_source.dart';
import '../datasources/invoice_file_data_source.dart';
import '../datasources/invoice_pdf_data_source.dart';
import '../mappers/invoice_page_raster_mapper.dart';
import '../mappers/invoice_pdf_mapper.dart';
import '../models/invoice_pdf_labels.dart';

/// The invoice PDF: the order written out in the chosen language (the words
/// from that language's i18n file), laid out off the UI isolate, drawn page
/// by page for the preview, then handed to the system's save / share / print
/// screens.
class InvoiceRepositoryImpl
    with BaseRepositoryMixin
    implements InvoiceRepository {
  InvoiceRepositoryImpl({
    required this._assets,
    required this._pdf,
    required this._files,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final InvoiceAssetsDataSource _assets;
  final InvoicePdfDataSource _pdf;
  final InvoiceFileDataSource _files;

  /// "Downloaded on …" (a test pins it).
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, InvoiceDocument>> buildPdf(
    OrderEntity order,
    InvoiceLanguage language,
  ) => execute(() async {
    // One after the other: a record's `.wait` would wrap a CacheException in
    // a ParallelWaitError (→ UnexpectedFailure). The words are kept after the
    // first build, so nothing is lost.
    final strings = await _assets.labels(language.code);
    final assets = await _assets.pdfAssets();
    final file = await _pdf.render(
      order.toInvoicePdfModel(
        language: language,
        labels: InvoicePdfLabels(strings),
        issuedAt: _clock(),
      ),
      assets,
    );
    return InvoiceDocument(
      bytes: file.bytes,
      fileName: InvoiceDocument.fileNameFor(order.orderNumber, language),
      language: language,
      pageCount: file.pageCount,
    );
  });

  @override
  Future<Either<Failure, bool>> savePdf(InvoiceDocument document) =>
      execute(() => _files.save(document.bytes, document.fileName));

  @override
  Future<Either<Failure, bool>> sharePdf(
    InvoiceDocument document, {
    InvoiceShareOrigin? origin,
  }) => execute(
    () => _files.share(
      document.bytes,
      document.fileName,
      origin: origin == null
          ? null
          : Rect.fromLTWH(origin.left, origin.top, origin.width, origin.height),
    ),
  );

  @override
  Future<Either<Failure, bool>> printPdf(InvoiceDocument document) =>
      execute(() => _files.printDocument(document.bytes, document.fileName));

  @override
  Stream<InvoicePageImage> renderPages(
    InvoiceDocument document, {
    required double dpi,
  }) => guardStream(
    _files.renderPages(document.bytes, dpi).map((page) => page.toEntity()),
  );
}
