import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/invoice_document.dart';
import '../../domain/entities/invoice_language.dart';
import '../../domain/entities/invoice_share_origin.dart';
import '../../domain/usecases/build_invoice_pdf_usecase.dart';
import '../../domain/usecases/print_invoice_pdf_usecase.dart';
import '../../domain/usecases/save_invoice_pdf_usecase.dart';
import '../../domain/usecases/share_invoice_pdf_usecase.dart';
import 'invoice_export_state.dart';

/// The invoice as a PDF file: built for the order on screen in the language
/// the customer picks (the app's first), then saved, shared or printed
/// through the system's own screens.
///
/// Each language's file is kept while the order stays the same, so going
/// back and forth between English and Arabic never builds twice: a language
/// asked again while its build runs (a quick switch back, the sheet closed
/// and reopened) waits for that build, and a file a newer choice overtook is
/// still kept — it just does not take the screen. One system screen at a
/// time: a tap while one is up does nothing.
class InvoiceExportCubit extends Cubit<InvoiceExportState>
    with SafeCubitMixin<InvoiceExportState> {
  InvoiceExportCubit({
    required this._build,
    required this._save,
    required this._share,
    required this._print,
  }) : super(const InvoiceExportState());

  final BuildInvoicePdfUseCase _build;
  final SaveInvoicePdfUseCase _save;
  final ShareInvoicePdfUseCase _share;
  final PrintInvoicePdfUseCase _print;

  OrderEntity? _order;

  /// The files made from [_order], and the builds still running for it.
  final Map<InvoiceLanguage, InvoiceDocument> _documents =
      <InvoiceLanguage, InvoiceDocument>{};
  final Map<InvoiceLanguage, Future<Either<Failure, InvoiceDocument>>>
  _building = <InvoiceLanguage, Future<Either<Failure, InvoiceDocument>>>{};

  /// Bumped by every language shown; a build answers only its own.
  int _generation = 0;

  /// The export sheet opened on [order]. The first opening shows the file in
  /// [appLanguage]; a later one keeps the customer's last pick. A new copy of
  /// the order (a refresh) drops the files made from the old one.
  Future<void> prepare(OrderEntity order, InvoiceLanguage appLanguage) {
    final language = state.status == InvoiceExportStatus.idle
        ? appLanguage
        : state.language;
    if (order != _order) {
      _order = order;
      _documents.clear();
      _building.clear();
    }
    return _show(language);
  }

  /// The customer picked [language] (ignored while a system screen is up).
  Future<void> chooseLanguage(InvoiceLanguage language) {
    if (state.running != null) return Future<void>.value();
    if (language == state.language && !state.hasFailed) {
      return Future<void>.value();
    }
    return _show(language);
  }

  /// Builds the file again after a failure.
  Future<void> retry() => _show(state.language);

  Future<void> save() => _run(InvoiceExportAction.save, _save.call);

  /// [origin]: the Share button's box (an iPad's popover points at it).
  Future<void> share({InvoiceShareOrigin? origin}) => _run(
    InvoiceExportAction.share,
    (document) => _share(ShareInvoicePdfParams(document, origin: origin)),
  );

  Future<void> printDocument() => _run(InvoiceExportAction.print, _print.call);

  Future<void> _show(InvoiceLanguage language) async {
    final order = _order;
    if (order == null) return;
    final generation = ++_generation;
    final kept = _documents[language];
    if (kept != null) {
      safeEmit(
        state.copyWith(
          language: language,
          status: InvoiceExportStatus.ready,
          document: kept,
        ),
      );
      return;
    }
    safeEmit(
      state.copyWith(
        language: language,
        status: InvoiceExportStatus.building,
        clearDocument: true,
      ),
    );
    final build = _building[language] ??= _build(
      BuildInvoicePdfParams(order: order, language: language),
    );
    final result = await build;
    // A refreshed order took over meanwhile: this file is of the old copy.
    if (!identical(order, _order)) return;
    if (identical(_building[language], build)) _building.remove(language);
    // Kept even when a newer choice overtook it: a switch back shows it.
    result.fold((_) {}, (document) => _documents[language] = document);
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: InvoiceExportStatus.failed, failure: failure),
      ),
      (document) => safeEmit(
        state.copyWith(status: InvoiceExportStatus.ready, document: document),
      ),
    );
  }

  Future<void> _run(
    InvoiceExportAction action,
    Future<Either<Failure, bool>> Function(InvoiceDocument document) run,
  ) async {
    final document = state.document;
    if (document == null || !state.canAct) return;
    safeEmit(state.copyWith(running: action));
    final result = await run(document);
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(clearRunning: true, failure: failure)),
      (done) => safeEmit(
        state.copyWith(clearRunning: true, completed: done ? action : null),
      ),
    );
  }
}
