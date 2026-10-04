import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice_document.dart';
import '../repositories/invoice_repository.dart';

/// Opens the system print dialog with the invoice PDF: `true` once a print
/// job was made, `false` when the customer closed the dialog.
class PrintInvoicePdfUseCase implements UseCase<bool, InvoiceDocument> {
  const PrintInvoicePdfUseCase(this._repository);

  final InvoiceRepository _repository;

  @override
  Future<Either<Failure, bool>> call(InvoiceDocument params) =>
      _repository.printPdf(params);
}
