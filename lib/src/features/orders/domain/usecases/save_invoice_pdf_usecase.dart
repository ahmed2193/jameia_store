import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice_document.dart';
import '../repositories/invoice_repository.dart';

/// Saves the invoice PDF where the customer picks: `true` once saved,
/// `false` when they backed out of the system dialog.
class SaveInvoicePdfUseCase implements UseCase<bool, InvoiceDocument> {
  const SaveInvoicePdfUseCase(this._repository);

  final InvoiceRepository _repository;

  @override
  Future<Either<Failure, bool>> call(InvoiceDocument params) =>
      _repository.savePdf(params);
}
