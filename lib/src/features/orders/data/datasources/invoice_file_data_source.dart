import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/error/exceptions.dart';
import '../models/invoice_page_raster_model.dart';

/// Draws pages of a PDF ([Printing.raster]'s shape; a test hands in its own).
typedef InvoicePdfRasterizer = Stream<PdfRaster> Function(
  Uint8List document, {
  List<int>? pages,
  double dpi,
});

/// The system's own screens for a ready PDF: save, share, print — and its
/// PDF renderer for the preview. None needs a permission: the customer picks
/// the place in the system's dialog.
abstract class InvoiceFileDataSource {
  /// Android "Save to…" (Storage Access Framework) / iOS "Save to Files":
  /// `true` once written, `false` when the customer backed out. Throws
  /// [CacheException].
  Future<bool> save(Uint8List bytes, String fileName);

  /// The share sheet; an iPad's popover points at [origin]. Throws
  /// [CacheException].
  Future<bool> share(Uint8List bytes, String fileName, {Rect? origin});

  /// The print dialog (Android's also offers "Save as PDF"): `true` once a
  /// job was made. Throws [CacheException].
  Future<bool> printDocument(Uint8List bytes, String fileName);

  /// Every page of [bytes] drawn at [dpi] (Android's PdfRenderer, iOS's
  /// PDFKit) and encoded as PNG, first page first. Ends with a
  /// [CacheException] when the renderer fails.
  Stream<InvoicePageRasterModel> renderPages(Uint8List bytes, double dpi);
}

class InvoiceFileDataSourceImpl implements InvoiceFileDataSource {
  const InvoiceFileDataSourceImpl({this._rasterize = Printing.raster});

  final InvoicePdfRasterizer _rasterize;

  static const String _pdfMimeType = 'application/pdf';
  static const String _pdfExtension = '.pdf';

  @override
  Future<bool> save(Uint8List bytes, String fileName) => _guard(() async {
    final path = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: const [_pdfMimeType],
      ),
    );
    return path != null;
  });

  @override
  Future<bool> share(Uint8List bytes, String fileName, {Rect? origin}) =>
      _guard(
        () =>
            Printing.sharePdf(bytes: bytes, filename: fileName, bounds: origin),
      );

  @override
  Future<bool> printDocument(Uint8List bytes, String fileName) => _guard(
    () => Printing.layoutPdf(
      onLayout: (_) async => bytes,
      // The print queue (and Android's "Save as PDF") adds the extension.
      name: fileName.endsWith(_pdfExtension)
          ? fileName.substring(0, fileName.length - _pdfExtension.length)
          : fileName,
      format: PdfPageFormat.a4,
      dynamicLayout: false,
    ),
  );

  @override
  Stream<InvoicePageRasterModel> renderPages(
    Uint8List bytes,
    double dpi,
  ) async* {
    var index = 0;
    try {
      await for (final page in _rasterize(bytes, dpi: dpi)) {
        yield InvoicePageRasterModel(
          index: index++,
          png: await page.toPng(),
          width: page.width,
          height: page.height,
        );
      }
    } on PlatformException catch (error) {
      throw CacheException('invoice preview: ${error.code} ${error.message}');
    } on MissingPluginException catch (error) {
      throw CacheException('invoice preview: $error');
    }
  }

  Future<bool> _guard(Future<bool> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw CacheException('invoice file: ${error.code} ${error.message}');
    } on MissingPluginException catch (error) {
      throw CacheException('invoice file: $error');
    }
  }
}
