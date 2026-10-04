// The invoice repository: words + assets → the written-out model → the
// layout, the document it returns, the system screens it hands the file
// to, the preview's pages, and every exception mapped to a Failure.
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_assets_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_file_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_pdf_data_source.dart';
import 'package:hero_mart/src/features/orders/data/models/invoice_page_raster_model.dart';
import 'package:hero_mart/src/features/orders/data/models/invoice_pdf_assets_model.dart';
import 'package:hero_mart/src/features/orders/data/models/invoice_pdf_file_model.dart';
import 'package:hero_mart/src/features/orders/data/models/invoice_pdf_model.dart';
import 'package:hero_mart/src/features/orders/data/repositories/invoice_repository_impl.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_page_image.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_share_origin.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'invoice_test_fixtures.dart';

class _Assets implements InvoiceAssetsDataSource {
  final List<String> asked = <String>[];
  bool fail = false;

  @override
  Future<Map<String, String>> labels(String languageCode) async {
    asked.add(languageCode);
    if (fail) throw const CacheException('no labels');
    return {'orders.invoice_title': 'Invoice ($languageCode)'};
  }

  @override
  Future<InvoicePdfAssetsModel> pdfAssets() async => InvoicePdfAssetsModel(
    latinRegular: ByteData(0),
    latinBold: ByteData(0),
    arabicRegular: ByteData(0),
    arabicBold: ByteData(0),
    logoPng: Uint8List(0),
  );
}

class _Pdf implements InvoicePdfDataSource {
  InvoicePdfModel? rendered;
  bool fail = false;

  @override
  Future<InvoicePdfFileModel> render(
    InvoicePdfModel invoice,
    InvoicePdfAssetsModel assets,
  ) async {
    if (fail) throw const CacheException('layout');
    rendered = invoice;
    return InvoicePdfFileModel(bytes: Uint8List(3), pageCount: 2);
  }
}

class _Files implements InvoiceFileDataSource {
  final List<String> calls = <String>[];
  Rect? origin;
  bool answer = true;
  bool fail = false;

  Future<bool> _call(String name) async {
    calls.add(name);
    if (fail) throw const CacheException('no app for that');
    return answer;
  }

  @override
  Future<bool> save(Uint8List bytes, String fileName) =>
      _call('save:$fileName:${bytes.length}');

  @override
  Future<bool> share(Uint8List bytes, String fileName, {Rect? origin}) {
    this.origin = origin;
    return _call('share:$fileName');
  }

  @override
  Future<bool> printDocument(Uint8List bytes, String fileName) =>
      _call('print:$fileName');

  /// Draws [pages] pages, then fails when [fail] is set.
  int pages = 2;
  double? dpi;

  @override
  Stream<InvoicePageRasterModel> renderPages(
    Uint8List bytes,
    double dpi,
  ) async* {
    this.dpi = dpi;
    for (var index = 0; index < pages; index++) {
      yield InvoicePageRasterModel(
        index: index,
        png: Uint8List(bytes.length),
        width: 10,
        height: 14,
      );
    }
    if (fail) throw const CacheException('renderer gone');
  }
}

void main() {
  setUpAll(initializeDateFormatting);

  late _Assets assets;
  late _Pdf pdf;
  late _Files files;
  late InvoiceRepositoryImpl repository;

  setUp(() {
    assets = _Assets();
    pdf = _Pdf();
    files = _Files();
    repository = InvoiceRepositoryImpl(
      assets: assets,
      pdf: pdf,
      files: files,
      clock: () => DateTime(2026, 10, 1, 21, 40),
    );
  });

  group('buildPdf', () {
    test('the chosen language’s words, the layout’s file, the name', () async {
      final result = await repository.buildPdf(
        fullInvoiceOrder(),
        InvoiceLanguage.arabic,
      );

      final document = result.getOrElse(() => fail('no document'));
      expect(assets.asked, ['ar']);
      expect(pdf.rendered?.rtl, isTrue);
      expect(pdf.rendered?.title, 'Invoice (ar)');
      expect(document.fileName, 'Hero-Invoice-HM-10234-AR.pdf');
      expect(document.pageCount, 2);
      expect(document.sizeInBytes, 3);
      expect(document.language, InvoiceLanguage.arabic);
    });

    test('unreadable words → CacheFailure', () async {
      assets.fail = true;
      final result = await repository.buildPdf(
        fullInvoiceOrder(),
        InvoiceLanguage.english,
      );
      expect(result, const Left<Failure, Object>(CacheFailure('no labels')));
    });

    test('a failed layout → CacheFailure', () async {
      pdf.fail = true;
      final result = await repository.buildPdf(
        fullInvoiceOrder(),
        InvoiceLanguage.english,
      );
      expect(result.isLeft(), isTrue);
      result.leftMap((failure) => expect(failure, isA<CacheFailure>()));
    });
  });

  group('the system screens', () {
    final document = fakeInvoiceDocument(size: 7);

    test('save, share and print get the file and its name', () async {
      expect(
        await repository.savePdf(document),
        const Right<Failure, bool>(true),
      );
      expect(
        await repository.sharePdf(
          document,
          origin: const InvoiceShareOrigin(
            left: 10,
            top: 20,
            width: 100,
            height: 44,
          ),
        ),
        const Right<Failure, bool>(true),
      );
      expect(
        await repository.printPdf(document),
        const Right<Failure, bool>(true),
      );

      expect(files.calls, [
        'save:Hero-Invoice-HM-10234-EN.pdf:7',
        'share:Hero-Invoice-HM-10234-EN.pdf',
        'print:Hero-Invoice-HM-10234-EN.pdf',
      ]);
      expect(files.origin, const Rect.fromLTWH(10, 20, 100, 44));
    });

    test('backing out is an answer, not a failure', () async {
      files.answer = false;
      expect(
        await repository.savePdf(document),
        const Right<Failure, bool>(false),
      );
    });

    test('a platform error → CacheFailure', () async {
      files.fail = true;
      final result = await repository.printPdf(document);
      expect(
        result,
        const Left<Failure, bool>(CacheFailure('no app for that')),
      );
    });
  });

  group('renderPages', () {
    final document = fakeInvoiceDocument(size: 7);

    test('the pages in order, at the asked dpi', () async {
      final pages = await repository.renderPages(document, dpi: 150).toList();

      expect(files.dpi, 150);
      expect(pages.map((page) => page.index), [0, 1]);
      expect(pages.first.png, hasLength(7));
      expect(
        pages.first,
        isA<InvoicePageImage>()
            .having((page) => page.width, 'width', 10)
            .having((page) => page.aspectRatio, 'aspectRatio', 10 / 14),
      );
    });

    test('a renderer error → CacheFailure on the stream', () async {
      files.fail = true;
      await expectLater(
        repository.renderPages(document, dpi: 150),
        emitsInOrder(<Object>[
          isA<InvoicePageImage>(),
          isA<InvoicePageImage>(),
          emitsError(const CacheFailure('renderer gone')),
        ]),
      );
    });
  });
}
