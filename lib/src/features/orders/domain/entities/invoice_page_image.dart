import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// One page of the invoice PDF drawn as a picture (PNG) for the preview:
/// where it sits in the file and its size in pixels.
class InvoicePageImage extends Equatable {
  const InvoicePageImage({
    required this.index,
    required this.png,
    required this.width,
    required this.height,
  });

  /// From 0.
  final int index;
  final Uint8List png;
  final int width;
  final int height;

  /// Width over height, as the page is drawn.
  double get aspectRatio => width / height;

  /// The bytes stay out on purpose, as in `InvoiceDocument`: an equality
  /// check must never walk a picture.
  @override
  List<Object?> get props => [index, width, height, png.length];
}
