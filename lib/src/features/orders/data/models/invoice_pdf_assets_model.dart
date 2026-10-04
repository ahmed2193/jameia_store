import 'dart:typed_data';

/// What the invoice PDF embeds: the TrueType fonts for both scripts and the
/// brand logo, as bytes, so they cross to the isolate that lays it out.
class InvoicePdfAssetsModel {
  const InvoicePdfAssetsModel({
    required this.latinRegular,
    required this.latinBold,
    required this.arabicRegular,
    required this.arabicBold,
    required this.logoPng,
  });

  /// Noto Sans.
  final ByteData latinRegular;
  final ByteData latinBold;

  /// Noto Sans Arabic UI.
  final ByteData arabicRegular;
  final ByteData arabicBold;

  /// The app logo, decoded small (the size the header prints it at).
  final Uint8List logoPng;
}
