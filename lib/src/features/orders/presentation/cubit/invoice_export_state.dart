import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invoice_document.dart';
import '../../domain/entities/invoice_language.dart';

/// Where the invoice PDF stands.
enum InvoiceExportStatus { idle, building, ready, failed }

/// What the customer can do with the ready PDF.
enum InvoiceExportAction { save, share, print }

class InvoiceExportState extends Equatable {
  const InvoiceExportState({
    this.language = InvoiceLanguage.english,
    this.status = InvoiceExportStatus.idle,
    this.document,
    this.running,
    this.completed,
    this.failure,
  });

  /// The language the file is (being) written in.
  final InvoiceLanguage language;
  final InvoiceExportStatus status;

  /// The ready file, while [status] is ready.
  final InvoiceDocument? document;

  /// A system screen (save dialog, share sheet, print dialog) is up.
  final InvoiceExportAction? running;

  /// Once: the action that just went through (the sheet closes after a
  /// save, the page says so). Cleared by the next change.
  final InvoiceExportAction? completed;

  /// Once: why the file could not be made, or an action failed. Cleared by
  /// the next change.
  final Failure? failure;

  bool get hasFailed => status == InvoiceExportStatus.failed;

  /// A ready file and no system screen up: the actions take taps.
  bool get canAct =>
      status == InvoiceExportStatus.ready &&
      document != null &&
      running == null;

  InvoiceExportState copyWith({
    InvoiceLanguage? language,
    InvoiceExportStatus? status,
    InvoiceDocument? document,
    bool clearDocument = false,
    InvoiceExportAction? running,
    bool clearRunning = false,
    InvoiceExportAction? completed,
    Failure? failure,
  }) => InvoiceExportState(
    language: language ?? this.language,
    status: status ?? this.status,
    document: clearDocument ? null : document ?? this.document,
    running: clearRunning ? null : running ?? this.running,
    completed: completed,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    language,
    status,
    document,
    running,
    completed,
    failure,
  ];
}
