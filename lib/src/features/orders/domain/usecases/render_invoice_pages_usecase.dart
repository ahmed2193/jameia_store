import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/invoice_document.dart';
import '../entities/invoice_page_image.dart';
import '../repositories/invoice_repository.dart';

/// Draws the invoice PDF's pages as pictures for the preview, first page
/// first; a page that cannot be drawn ends the stream with its `Failure`.
class RenderInvoicePagesUseCase
    implements StreamUseCase<InvoicePageImage, RenderInvoicePagesParams> {
  const RenderInvoicePagesUseCase(this._repository);

  final InvoiceRepository _repository;

  @override
  Stream<InvoicePageImage> call(RenderInvoicePagesParams params) =>
      _repository.renderPages(params.document, dpi: params.dpi);
}

class RenderInvoicePagesParams extends Equatable {
  const RenderInvoicePagesParams(this.document, {required this.dpi});

  final InvoiceDocument document;

  /// Dots per inch: 72 draws a point as a pixel.
  final double dpi;

  @override
  List<Object?> get props => [document, dpi];
}
