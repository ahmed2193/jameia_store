import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';

// Re-export the map value types so feature screens import only this widget.
export 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        LatLng,
        Marker,
        MarkerId,
        Polyline,
        PolylineId,
        BitmapDescriptor,
        CameraPosition,
        CameraUpdate,
        GoogleMapController;

/// Single Google-Maps surface for the whole app (KeeTa map screens: order
/// tracking, order map, shop map, address edit, choose-location).
///
/// Centralises the `GoogleMap` config so every map looks/behaves the same and
/// the API-key wiring lives in one mental place (native manifest/AppDelegate).
/// Feature screens overlay their own chrome (bottom cards, ETA bubbles, back
/// button) on top of this via a [Stack].
class KeetaMap extends StatelessWidget {
  const KeetaMap({
    super.key,
    required this.target,
    this.zoom = 14.5,
    this.markers = const {},
    this.polylines = const {},
    this.liteMode = false,
    this.interactive = true,
    this.myLocationEnabled = false,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
  });

  final LatLng target;
  final double zoom;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  /// Lite mode renders a lightweight static-ish bitmap map — ideal for the small
  /// embedded map card on the address/shop-detail screens.
  final bool liteMode;
  final bool interactive;
  final bool myLocationEnabled;
  final void Function(GoogleMapController)? onMapCreated;

  /// Fires as the user pans/zooms — used by the location picker to track the
  /// centre coordinate under a fixed pin.
  final void Function(CameraPosition)? onCameraMove;

  /// Fires when panning settles — the picker reverse-geocodes here.
  final VoidCallback? onCameraIdle;

  /// Fires when the user taps a point on the map — the picker animates the
  /// camera here so the fixed centre pin lands on the tapped coordinate.
  final void Function(LatLng)? onTap;

  /// Fires on a long-press — same tap-to-place behaviour as [onTap].
  final void Function(LatLng)? onLongPress;

  /// Convenience marker builder (default colored pin).
  static Marker pin(
    String id,
    LatLng pos, {
    double hue = BitmapDescriptor.hueRed,
    String? title,
  }) =>
      Marker(
        markerId: MarkerId(id),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: title == null ? InfoWindow.noText : InfoWindow(title: title),
      );

  /// Builds a marker from a REAL KeeTa asset image (rider/shop/user PNG/WEBP).
  /// Async — load these in initState/FutureBuilder then render the map with the
  /// resulting set. Falls back to a default marker if decoding fails.
  static Future<Marker> assetMarker(
    String id,
    LatLng pos,
    String assetPath, {
    String? title,
    Offset anchor = const Offset(0.5, 0.5),
    Size size = const Size(46, 46),
  }) async {
    BitmapDescriptor icon;
    try {
      icon = await BitmapDescriptor.asset(ImageConfiguration(size: size), assetPath);
    } catch (_) {
      icon = BitmapDescriptor.defaultMarker;
    }
    return Marker(
      markerId: MarkerId(id),
      position: pos,
      icon: icon,
      anchor: anchor,
      infoWindow: title == null ? InfoWindow.noText : InfoWindow(title: title),
    );
  }

  /// Builds a heading-rotated marker (rider) from a KeeTa asset. The asset is
  /// already drawn for [headingDegrees] (the 24-frame `carMarkerForHeading`), so
  /// the marker [rotation] is left at 0 by default; pass [rotateBitmap]:true to
  /// additionally rotate the bitmap on the map (use for a single-frame icon).
  static Future<Marker> headingMarker(
    String id,
    LatLng pos,
    String assetPath,
    int headingDegrees, {
    Offset anchor = const Offset(0.5, 0.5),
    Size size = const Size(46, 46),
    bool rotateBitmap = false,
  }) async {
    BitmapDescriptor icon;
    try {
      icon = await BitmapDescriptor.asset(ImageConfiguration(size: size), assetPath);
    } catch (_) {
      icon = BitmapDescriptor.defaultMarker;
    }
    return Marker(
      markerId: MarkerId(id),
      position: pos,
      icon: icon,
      anchor: anchor,
      rotation: rotateBitmap ? headingDegrees.toDouble() : 0,
      flat: true,
      infoWindow: InfoWindow.noText,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Key the platform view by locale so the Google Map is recreated when the
    // app language switches — the native Maps SDK reads the locale at creation,
    // so a fresh view picks up Arabic/English labels to match the app.
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return GoogleMap(
      key: ValueKey('keeta_map_$lang'),
      initialCameraPosition: CameraPosition(target: target, zoom: zoom),
      markers: markers,
      polylines: polylines,
      liteModeEnabled: liteMode,
      onMapCreated: onMapCreated,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      onTap: onTap,
      onLongPress: onLongPress,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: interactive,
      scrollGesturesEnabled: interactive,
      tiltGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      // Neutral KeeTa-ish loading background while tiles fetch.
      style: null,
    );
  }
}

/// Rounded map card (embedded preview, e.g. address/shop detail).
class KeetaMapCard extends StatelessWidget {
  const KeetaMapCard({
    super.key,
    required this.target,
    this.height = 160,
    this.markers = const {},
    this.radius = 12,
  });

  final LatLng target;
  final double height;
  final Set<Marker> markers;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        color: AppColors.smallBackground,
        child: KeetaMap(
          target: target,
          markers: markers,
          liteMode: true,
          interactive: false,
        ),
      ),
    );
  }
}
