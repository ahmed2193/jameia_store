import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice_document.dart';
import '../entities/invoice_share_origin.dart';
import '../repositories/invoice_repository.dart';

/// Hands the invoice PDF to the system share sheet.
class ShareInvoicePdfUseCase implements UseCase<bool, ShareInvoicePdfParams> {
  const ShareInvoicePdfUseCase(this._repository);

  final InvoiceRepository _repository;

  @override
  Future<Either<Failure, bool>> call(ShareInvoicePdfParams params) =>
      _repository.sharePdf(params.document, origin: params.origin);
}

class ShareInvoicePdfParams extends Equatable {
  const ShareInvoicePdfParams(this.document, {this.origin});

  final InvoiceDocument document;

  /// The Share button's box (an iPad's popover points at it).
  final InvoiceShareOrigin? origin;

  @override
  List<Object?> get props => [document, origin];
}
