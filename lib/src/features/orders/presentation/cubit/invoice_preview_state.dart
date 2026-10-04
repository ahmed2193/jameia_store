import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invoice_document.dart';
import '../../domain/entities/invoice_page_image.dart';

/// Where the preview of the invoice PDF stands.
enum InvoicePreviewStatus { idle, drawing, ready, failed }

class InvoicePreviewState extends Equatable {
  const InvoicePreviewState({
    this.status = InvoicePreviewStatus.idle,
    this.document,
    this.pages = const <InvoicePageImage>[],
    this.failure,
  });

  final InvoicePreviewStatus status;

  /// The file the pages are of; `null` while no file is ready.
  final InvoiceDocument? document;

  /// The pages drawn so far, in order.
  final List<InvoicePageImage> pages;

  /// Why the pages could not be drawn (with [InvoicePreviewStatus.failed]).
  final Failure? failure;

  /// The pages the file has: those not drawn yet show as blank sheets.
  int get pageCount => document?.pageCount ?? 0;

  InvoicePreviewState copyWith({
    InvoicePreviewStatus? status,
    List<InvoicePageImage>? pages,
    Failure? failure,
  }) => InvoicePreviewState(
    status: status ?? this.status,
    document: document,
    pages: pages ?? this.pages,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, document, pages, failure];
}
