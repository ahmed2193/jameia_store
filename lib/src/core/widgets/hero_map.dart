import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../motion/motion.dart';

// Re-export the map value types so feature screens import only this widget.
export 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        LatLng,
        LatLngBounds,
        Marker,
        MarkerId,
        Polyline,
        PolylineId,
        PatternItem,
        JointType,
        Cap,
        Circle,
        CircleId,
        BitmapDescriptor,
        CameraPosition,
        CameraUpdate,
        MinMaxZoomPreference,
        GoogleMapController;

/// Single Google-Maps surface for the whole app (Hero map screens: order
/// tracking, order map, shop map, address edit, choose-location).
///
/// Centralises the `GoogleMap` config so every map looks/behaves the same and
/// the API-key wiring lives in one mental place (native manifest/AppDelegate).
/// Feature screens overlay their own chrome (bottom cards, ETA bubbles, back
/// button) on top of this via a [Stack].
class HeroMap extends StatelessWidget {
  const HeroMap({
    super.key,
    required this.target,
    this.zoom = 14.5,
    this.markers = const {},
    this.polylines = const {},
    this.circles = const {},
    this.padding = EdgeInsets.zero,
    this.style,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
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
  final Set<Circle> circles;

  /// Room the screen's own chrome takes over the map (a bottom card, a top
  /// bar): the camera centres and fits bounds in what is left, and the
  /// Google logo stays in sight.
  final EdgeInsets padding;

  /// A JSON map style (`HeroMapStyle.brand` for the Hero look); `null` = the
  /// default Google style.
  final String? style;

  /// How far the camera may zoom, by gesture or by a camera update.
  final MinMaxZoomPreference minMaxZoomPreference;

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

  @override
  Widget build(BuildContext context) {
    // Key the platform view by locale so the Google Map is recreated when the
    // app language switches — the native Maps SDK reads the locale at creation,
    // so a fresh view picks up Arabic/English labels to match the app.
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return GoogleMap(
      key: ValueKey('hero_map_$lang'),
      initialCameraPosition: CameraPosition(target: target, zoom: zoom),
      markers: markers,
      polylines: polylines,
      circles: circles,
      padding: padding,
      minMaxZoomPreference: minMaxZoomPreference,
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
      style: style,
    );
  }
}

/// The native map camera never reads Flutter's reduced-motion setting, so
/// every programmatic camera move goes through here: a glide normally, a
/// jump ([GoogleMapController.moveCamera]) under reduced motion
/// ([MotionGuard.reduced]). The glide takes [AppMotion.cameraGlide], not the
/// native SDK's own length, which differs between Android and iOS.
extension HeroMapCamera on GoogleMapController {
  Future<void> glideTo(BuildContext context, CameraUpdate update) =>
      MotionGuard.reduced(context)
      ? moveCamera(update)
      : animateCamera(update, duration: AppMotion.cameraGlide);
}
