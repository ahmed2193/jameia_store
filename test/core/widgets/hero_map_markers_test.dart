// MM-2 / DEVICE-7: the map markers drawn from the SVG art. The rasterisers
// free their Picture and Image even when a step throws; these smoke tests
// prove the output is unchanged, that a labelled pin reports its logical
// size so the camera can keep the whole marker in frame, and that a marker
// that fails to load is forgotten without an unhandled error.
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/widgets/hero_map_markers.dart';

/// A PNG's width and height, from its header.
(int, int) _sizeOf(Uint8List png) {
  final header = ByteData.sublistView(png, 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  const pngMagic = [0x89, 0x50, 0x4E, 0x47];

  testWidgets('a marker is the SVG as a PNG at the screen density', (
    tester,
  ) async {
    final icon = await tester.runAsync(
      () => HeroMapMarkers.svg(
        HeroAssets.mapRider,
        size: const Size(36, 44),
        pixelRatio: 3,
      ),
    );

    expect(icon, isA<BytesMapBitmap>());
    final bitmap = icon! as BytesMapBitmap;
    expect(bitmap.byteData.sublist(0, 4), pngMagic);
    expect(_sizeOf(bitmap.byteData), (108, 132));
    expect(bitmap.imagePixelRatio, 3);
  });

  testWidgets('a named pin reports its logical size, name bubble included', (
    tester,
  ) async {
    const pin = Size(40, 48);
    const pixelRatio = 2.0;
    final marker = await tester.runAsync(
      () => HeroMapMarkers.labelledPin(
        HeroAssets.mapStorePin,
        size: pin,
        pinTip: const Offset(0.5, 53 / 58),
        label: 'Hero · Salmiya',
        style: const TextStyle(fontSize: 12),
        textDirection: TextDirection.ltr,
        pixelRatio: pixelRatio,
      ),
    );

    final bitmap = marker!.icon as BytesMapBitmap;
    expect(bitmap.byteData.sublist(0, 4), pngMagic);
    // The bubble sits over the pin: the marker is taller than the pin art
    // and at least as wide.
    expect(marker.size.height, greaterThan(pin.height));
    expect(marker.size.width, greaterThanOrEqualTo(pin.width));
    // The size is logical: the bitmap is that size times the density.
    expect(_sizeOf(bitmap.byteData), (
      (marker.size.width * pixelRatio).round(),
      (marker.size.height * pixelRatio).round(),
    ));
  });

  testWidgets('a marker that fails to load is forgotten, and fails quietly', (
    tester,
  ) async {
    const missing = 'assets/svg/__missing_map_marker__.svg';
    Future<BitmapDescriptor> load() =>
        HeroMapMarkers.svg(missing, size: const Size(36, 44), pixelRatio: 3);
    final loads = await tester.runAsync(() async {
      final first = load();
      await expectLater(first, throwsA(anything));
      // The cache's own error handler runs here: dropping the failed load
      // must not raise the error again (an unhandled async error fails the
      // test).
      await Future<void>.delayed(Duration.zero);
      final second = load();
      await expectLater(second, throwsA(anything));
      await Future<void>.delayed(Duration.zero);
      return (first, second);
    });
    await tester.pump();
    final (first, second) = loads!;
    // Not kept: the next call tries again.
    expect(identical(first, second), isFalse);
  });
}
