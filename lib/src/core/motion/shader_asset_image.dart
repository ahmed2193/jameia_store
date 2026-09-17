import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// Loads (and caches) a [ui.Image] from an asset path.
Future<ui.Image> loadShaderAssetImage(String path) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}
