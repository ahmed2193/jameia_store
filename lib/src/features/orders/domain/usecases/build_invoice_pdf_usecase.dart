import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice_document.dart';
import '../entities/invoice_language.dart';
import '../repositories/invoice_repository.dart';

/// Lays an order's invoice out as a PDF in the chosen language.
class BuildInvoicePdfUseCase
    implements UseCase<InvoiceDocument, BuildInvoicePdfParams> {
  const BuildInvoicePdfUseCase(this._repository);

  final InvoiceRepository _repository;

  @override
  Future<Either<Failure, InvoiceDocument>> call(BuildInvoicePdfParams params) =>
      _repository.buildPdf(params.order, params.language);
}

class BuildInvoicePdfParams extends Equatable {
  const BuildInvoicePdfParams({required this.order, required this.language});

  final OrderEntity order;
  final InvoiceLanguage language;

  @override
  List<Object?> get props => [order, language];
}
