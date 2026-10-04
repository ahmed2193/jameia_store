import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/invoice_document.dart';
import '../entities/invoice_language.dart';
import '../entities/invoice_page_image.dart';
import '../entities/invoice_share_origin.dart';

/// The order's invoice as a PDF file: laid out on the device (the API has
/// no invoice file), drawn page by page for a preview, then saved, shared or
/// printed through the system's own screens. Every answer of the system dialogs is a `bool`: `true` once done,
/// `false` when the customer backed out.
abstract class InvoiceRepository {
  /// Lays [order]'s invoice out as A4 pages in [language].
  Future<Either<Failure, InvoiceDocument>> buildPdf(
    OrderEntity order,
    InvoiceLanguage language,
  );

  /// The system's "Save to…" dialog (Android) / "Save to Files" (iOS) with
  /// [document] — no storage permission involved.
  Future<Either<Failure, bool>> savePdf(InvoiceDocument document);

  /// The system share sheet with [document] attached; on an iPad it points
  /// at [origin].
  Future<Either<Failure, bool>> sharePdf(
    InvoiceDocument document, {
    InvoiceShareOrigin? origin,
  });

  /// The system print dialog with [document] (Android also offers "Save as
  /// PDF" there).
  Future<Either<Failure, bool>> printPdf(InvoiceDocument document);

  /// [document]'s pages as pictures at [dpi], first page first, by the
  /// system's own PDF renderer — the preview shows what the file holds. A
  /// page that cannot be drawn ends the stream with its [Failure].
  Stream<InvoicePageImage> renderPages(
    InvoiceDocument document, {
    required double dpi,
  });
}
