import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/invoice_document.dart';
import '../../domain/entities/invoice_page_image.dart';
import '../../domain/usecases/render_invoice_pages_usecase.dart';
import 'invoice_preview_state.dart';

/// The preview of the invoice PDF: the ready file's pages drawn as pictures
/// by the system's PDF renderer, one after the other, so the customer sees
/// exactly what they are about to save, share or print. Another file (the
/// other language) replaces the pages; no file (one being made) clears
/// them. One drawing at a time: a newer file cancels the older drawing.
class InvoicePreviewCubit extends Cubit<InvoicePreviewState>
    with SafeCubitMixin<InvoicePreviewState> {
  InvoicePreviewCubit(this._render) : super(const InvoicePreviewState());

  /// Sharp on a phone at full width with room to zoom in: an A4 page comes
  /// out at about 1650 × 2340 px.
  static const double dpi = 200;

  final RenderInvoicePagesUseCase _render;
  StreamSubscription<InvoicePageImage>? _drawing;

  /// Shows [document]'s pages (`null`: a file is being made).
  void show(InvoiceDocument? document) {
    if (document != null &&
        document == state.document &&
        state.status != InvoicePreviewStatus.failed) {
      return;
    }
    unawaited(_drawing?.cancel());
    _drawing = null;
    if (document == null) {
      safeEmit(const InvoicePreviewState());
      return;
    }
    safeEmit(
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: document,
      ),
    );
    _drawing = _render(RenderInvoicePagesParams(document, dpi: dpi)).listen(
      (page) => safeEmit(state.copyWith(pages: [...state.pages, page])),
      onError: (Object error) => safeEmit(
        state.copyWith(
          status: InvoicePreviewStatus.failed,
          failure: error is Failure ? error : const UnexpectedFailure(),
        ),
      ),
      onDone: () {
        if (state.status == InvoicePreviewStatus.drawing) {
          safeEmit(state.copyWith(status: InvoicePreviewStatus.ready));
        }
      },
      cancelOnError: true,
    );
  }

  /// Draws the pages again after a failure.
  void retry() => show(state.document);

  @override
  Future<void> close() async {
    await _drawing?.cancel();
    return super.close();
  }
}
