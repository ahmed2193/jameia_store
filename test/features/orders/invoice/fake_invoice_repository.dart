import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_document.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_page_image.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_share_origin.dart';
import 'package:hero_mart/src/features/orders/domain/repositories/invoice_repository.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/build_invoice_pdf_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/print_invoice_pdf_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/save_invoice_pdf_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/share_invoice_pdf_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/render_invoice_pages_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_export_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_preview_cubit.dart';

import 'invoice_test_fixtures.dart';

/// A 1 × 1 PNG: a real picture, so an `Image.memory` of a page decodes.
final Uint8List fakePagePng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0xFF, //
  0x7F, 0x00, 0x09, 0xFB, 0x03, 0xFD, 0x2A, 0x86, 0xE3, 0x8A, 0x00, 0x00, //
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

/// A drawn A4 page at the preview's size.
InvoicePageImage fakePageImage(int index) =>
    InvoicePageImage(index: index, png: fakePagePng, width: 1654, height: 2339);

/// Scripted invoice repository: records the calls (`build:en`, `save`,
/// `share`, `print`, `render:en`), can hold a build or an action open, and
/// can fail the next build, action or drawing.
class FakeInvoiceRepository implements InvoiceRepository {
  final List<String> calls = <String>[];

  /// Gates the next build in a language (a slow build overtaken).
  final Map<InvoiceLanguage, Completer<void>> buildGates =
      <InvoiceLanguage, Completer<void>>{};

  /// Gates the next save / share / print (a system screen still up).
  Completer<void>? actionGate;

  Failure? buildFailure;
  Failure? actionFailure;

  /// Fails the next drawing of the pages (after the first page).
  Failure? renderFailure;

  /// The picture of every page in a language (default [fakePagePng]): a
  /// screenshot test hands in the real PDF's pages.
  Uint8List Function(InvoiceLanguage language)? pagePngOf;

  /// What the system screens answer: `false` = the customer backed out.
  bool actionDone = true;

  InvoiceShareOrigin? lastOrigin;
  OrderEntity? lastOrder;

  @override
  Future<Either<Failure, InvoiceDocument>> buildPdf(
    OrderEntity order,
    InvoiceLanguage language,
  ) async {
    calls.add('build:${language.code}');
    lastOrder = order;
    await buildGates.remove(language)?.future;
    final failure = buildFailure;
    if (failure != null) {
      buildFailure = null;
      return Left(failure);
    }
    return Right(fakeInvoiceDocument(language: language));
  }

  @override
  Future<Either<Failure, bool>> savePdf(InvoiceDocument document) =>
      _act('save');

  @override
  Future<Either<Failure, bool>> sharePdf(
    InvoiceDocument document, {
    InvoiceShareOrigin? origin,
  }) {
    lastOrigin = origin;
    return _act('share');
  }

  @override
  Future<Either<Failure, bool>> printPdf(InvoiceDocument document) =>
      _act('print');

  @override
  Stream<InvoicePageImage> renderPages(
    InvoiceDocument document, {
    required double dpi,
  }) async* {
    calls.add('render:${document.language.code}');
    for (var index = 0; index < document.pageCount; index++) {
      final failure = renderFailure;
      if (failure != null && index > 0) {
        renderFailure = null;
        throw failure;
      }
      final png = pagePngOf?.call(document.language);
      yield png == null
          ? fakePageImage(index)
          : InvoicePageImage(
              index: index,
              png: png,
              width: fakePageImage(index).width,
              height: fakePageImage(index).height,
            );
    }
    final failure = renderFailure;
    if (failure != null) {
      renderFailure = null;
      throw failure;
    }
  }

  Future<Either<Failure, bool>> _act(String name) async {
    calls.add(name);
    final gate = actionGate;
    actionGate = null;
    await gate?.future;
    final failure = actionFailure;
    if (failure != null) {
      actionFailure = null;
      return Left(failure);
    }
    return Right(actionDone);
  }
}

/// The preview cubit on the real use case over [repository].
InvoicePreviewCubit invoicePreviewCubit(FakeInvoiceRepository repository) =>
    InvoicePreviewCubit(RenderInvoicePagesUseCase(repository));

/// The export cubit on real use cases over [repository].
InvoiceExportCubit invoiceExportCubit(FakeInvoiceRepository repository) =>
    InvoiceExportCubit(
      build: BuildInvoicePdfUseCase(repository),
      save: SaveInvoicePdfUseCase(repository),
      share: ShareInvoicePdfUseCase(repository),
      print: PrintInvoicePdfUseCase(repository),
    );
