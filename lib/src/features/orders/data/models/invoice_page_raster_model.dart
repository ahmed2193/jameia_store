import 'dart:typed_data';

/// One PDF page as the system's PDF renderer drew it, encoded as PNG.
class InvoicePageRasterModel {
  const InvoicePageRasterModel({
    required this.index,
    required this.png,
    required this.width,
    required this.height,
  });

  final int index;
  final Uint8List png;
  final int width;
  final int height;
}
