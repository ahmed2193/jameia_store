import 'dart:typed_data';

/// The laid-out invoice: the PDF file's bytes and how many pages it has.
class InvoicePdfFileModel {
  const InvoicePdfFileModel({required this.bytes, required this.pageCount});

  final Uint8List bytes;
  final int pageCount;
}
