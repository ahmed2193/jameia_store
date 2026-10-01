import 'package:flutter/painting.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_map.dart';
import '../../../../../core/widgets/hero_map_markers.dart';

/// The live map's three markers as map bitmaps, rasterised once for the
/// screen's density ([HeroMapMarkers]): the rider (seen from above, riding
/// north — the map turns it with the road), the Hero store pin with the
/// store's name over it, and the home pin.
class LiveMapMarkerIcons {
  const LiveMapMarkerIcons({
    required this.rider,
    required this.store,
    required this.home,
    this.storeAnchor = pinTip,
    this.storeSize = pinSize,
  });

  static const Size riderSize = Size.square(AppSize.s44);
  static const Size pinSize = Size(AppSize.s40, AppSize.s48);

  /// Where the rider is on its bitmap (its middle: it turns about it).
  static const Offset riderAnchor = Offset(0.5, 0.5);

  /// Where a pin's tip is on its bitmap — the point it marks (the art is
  /// 48 × 58 with the tip at 53).
  static const Offset pinTip = Offset(0.5, 53 / 58);

  final BitmapDescriptor rider;
  final BitmapDescriptor store;
  final BitmapDescriptor home;

  /// Where the store pin's tip is on its bitmap (under the name bubble).
  final Offset storeAnchor;

  /// The store pin's size in logical pixels, name bubble included: the
  /// camera keeps that much room at the frame's edge
  /// (`LiveMapCamera.framePaddingFor`).
  final Size storeSize;

  /// Google's own pins, for when the art cannot be drawn: the map still
  /// shows who is where.
  static final LiveMapMarkerIcons fallback = LiveMapMarkerIcons(
    rider: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    store: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    home: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
  );

  /// The art for a screen of [pixelRatio], the store pin named [storeLabel]
  /// (in [labelStyle], read [textDirection]).
  static Future<LiveMapMarkerIcons> load(
    double pixelRatio, {
    required String storeLabel,
    required TextStyle labelStyle,
    required TextDirection textDirection,
  }) async {
    final (rider, store, home) = await (
      HeroMapMarkers.svg(
        HeroAssets.mapRider,
        size: riderSize,
        pixelRatio: pixelRatio,
      ),
      HeroMapMarkers.labelledPin(
        HeroAssets.mapStorePin,
        size: pinSize,
        pinTip: pinTip,
        label: storeLabel,
        style: labelStyle,
        textDirection: textDirection,
        pixelRatio: pixelRatio,
      ),
      HeroMapMarkers.svg(
        HeroAssets.mapHomePin,
        size: pinSize,
        pixelRatio: pixelRatio,
      ),
    ).wait;
    return LiveMapMarkerIcons(
      rider: rider,
      store: store.icon,
      storeAnchor: store.anchor,
      storeSize: store.size,
      home: home,
    );
  }
}
