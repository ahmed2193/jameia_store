// The pictures drawn for the notification shade and the map: the ride
// strip of a live card, and the store pin named on the map.
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/notifications/local_alert_track_picture.dart';
import 'package:hero_mart/src/core/notifications/local_alerts.dart';
import 'package:hero_mart/src/core/widgets/hero_map_markers.dart';

/// A PNG's width and height, from its header.
(int, int) _sizeOf(Uint8List png) {
  final header = ByteData.sublistView(png, 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  const pngMagic = [0x89, 0x50, 0x4E, 0x47];

  testWidgets('a live card draws the ride as a wide strip, either way round', (
    tester,
  ) async {
    final pictures = await tester.runAsync(
      () => Future.wait([
        LocalAlertTrackPicture.render(const LocalAlertTrack(progress: 0.4)),
        LocalAlertTrackPicture.render(
          const LocalAlertTrack(progress: 1.4, rightToLeft: true),
        ),
      ]),
    );

    for (final png in pictures!) {
      expect(png.sublist(0, 4), pngMagic);
      final (width, height) = _sizeOf(png);
      expect(width / height, greaterThan(3));
    }
  });

  testWidgets('the pins and the rider are decoded once for every card', (
    tester,
  ) async {
    const track = LocalAlertTrack(progress: 0.6);
    final pictures = await tester.runAsync(() async {
      final first = await LocalAlertTrackPicture.render(track);
      final again = await LocalAlertTrackPicture.render(track);
      return (first, again);
    });

    final (first, again) = pictures!;
    expect(LocalAlertTrackPicture.artLoads, 1);
    // The kept art draws the very same card.
    expect(again, first);
  });

  testWidgets('the store pin carries its name, anchored at the pin tip', (
    tester,
  ) async {
    const pinTip = Offset(0.5, 53 / 58);
    final marker = await tester.runAsync(
      () => HeroMapMarkers.labelledPin(
        HeroAssets.mapStorePin,
        size: const Size(40, 48),
        pinTip: pinTip,
        label: 'Hero · Salmiya',
        style: const TextStyle(fontSize: 12),
        textDirection: TextDirection.ltr,
        pixelRatio: 2,
      ),
    );

    // The name sits over the pin: the tip is lower on the taller bitmap.
    expect(marker!.anchor.dx, 0.5);
    expect(marker.anchor.dy, greaterThan(pinTip.dy));
    expect(marker.anchor.dy, lessThan(1));
  });
}
