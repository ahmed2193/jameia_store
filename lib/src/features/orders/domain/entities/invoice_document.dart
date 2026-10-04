import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'invoice_language.dart';

/// An order's invoice as a ready PDF file: its bytes and the name it is
/// saved and shared under. Built on the device from the order the invoice
/// page shows — the API serves no invoice file.
class InvoiceDocument extends Equatable {
  const InvoiceDocument({
    required this.bytes,
    required this.fileName,
    required this.language,
    required this.pageCount,
  });

  /// Width over height of the file's pages (A4 portrait, 210 × 297 mm).
  static const double pageAspectRatio = 210 / 297;

  static const String _prefix = 'Hero-Invoice';
  static const String _extension = '.pdf';

  /// Anything but letters, digits, `-` and `_` in an order number.
  static final RegExp _unsafe = RegExp('[^A-Za-z0-9_-]+');

  final Uint8List bytes;

  /// `Hero-Invoice-<order number>-<EN|AR>.pdf` ([fileNameFor]).
  final String fileName;
  final InvoiceLanguage language;
  final int pageCount;

  int get sizeInBytes => bytes.length;

  /// The file name for [orderNumber]'s invoice in [language]: Latin only and
  /// free of path characters, so every file manager, mail app and printer
  /// queue takes it as it is.
  static String fileNameFor(String orderNumber, InvoiceLanguage language) {
    final number = orderNumber.trim().replaceAll(_unsafe, '-');
    final parts = [
      _prefix,
      if (number.isNotEmpty) number,
      language.code.toUpperCase(),
    ];
    return '${parts.join('-')}$_extension';
  }

  /// The bytes stay out on purpose: a document is told apart by its name,
  /// language, pages and size, and an equality check must never walk a
  /// 100 KB buffer.
  @override
  List<Object?> get props => [fileName, language, pageCount, sizeInBytes];
}
