import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/theme/app_colors.dart';
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

/// Single Google-Maps surface for the whole app (the address picker and the
/// live rider map).
///
/// Centralises the `GoogleMap` config so every map looks and behaves the
/// same (no native buttons, toolbar or compass: each screen draws its own
/// round map buttons), and the API-key wiring lives in one mental place
/// (native manifest / AppDelegate). Feature screens overlay their own
/// chrome on top of it through a [Stack].
///
/// A fresh native map shows blank tiles for a moment; a veil in the page's
/// background colour covers it until the map first settles (or
/// [_revealAfter] at the latest), then fades away. Only the veil rebuilds
/// for it: every rebuild of the native map sends the platform a round of
/// updates.
class HeroMap extends StatefulWidget {
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
    this.onCameraMoveStarted,
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

  /// A JSON map style (`HeroMapStyle.brand` / `.picker` for the Hero look);
  /// `null` = the default Google style.
  final String? style;

  /// How far the camera may zoom, by gesture or by a camera update.
  final MinMaxZoomPreference minMaxZoomPreference;

  /// Lite mode renders a lightweight static-ish bitmap map (Android only).
  final bool liteMode;
  final bool interactive;

  /// The "you are here" dot (shown only once the app may read the location).
  final bool myLocationEnabled;
  final void Function(GoogleMapController)? onMapCreated;

  /// Fires when the camera starts to move — by a gesture or a camera update
  /// alike: the address picker lifts its pin here.
  final VoidCallback? onCameraMoveStarted;

  /// Fires as the camera moves — every frame: keep it cheap.
  final void Function(CameraPosition)? onCameraMove;

  /// Fires when the camera settles.
  final VoidCallback? onCameraIdle;

  /// Fires when the user taps a point on the map.
  final void Function(LatLng)? onTap;

  /// Fires on a long-press.
  final void Function(LatLng)? onLongPress;

  /// The longest the veil waits for the map to settle.
  static const Duration _revealAfter = Duration(milliseconds: 1500);

  @override
  State<HeroMap> createState() => _HeroMapState();
}

class _HeroMapState extends State<HeroMap> {
  final ValueNotifier<bool> _revealed = ValueNotifier<bool>(false);
  Timer? _fallback;

  void _created(GoogleMapController controller) {
    widget.onMapCreated?.call(controller);
    _fallback ??= Timer(HeroMap._revealAfter, _reveal);
  }

  void _idle() {
    _reveal();
    widget.onCameraIdle?.call();
  }

  void _reveal() {
    _fallback?.cancel();
    _revealed.value = true;
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _revealed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Key the platform view by locale so the Google Map is recreated when the
    // app language switches — the native Maps SDK reads the locale at creation,
    // so a fresh view picks up Arabic/English labels to match the app.
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final interactive = widget.interactive;
    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          key: ValueKey('hero_map_$lang'),
          initialCameraPosition: CameraPosition(
            target: widget.target,
            zoom: widget.zoom,
          ),
          markers: widget.markers,
          polylines: widget.polylines,
          circles: widget.circles,
          padding: widget.padding,
          minMaxZoomPreference: widget.minMaxZoomPreference,
          liteModeEnabled: widget.liteMode,
          onMapCreated: _created,
          onCameraMoveStarted: widget.onCameraMoveStarted,
          onCameraMove: widget.onCameraMove,
          onCameraIdle: _idle,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: interactive,
          scrollGesturesEnabled: interactive,
          tiltGesturesEnabled: interactive,
          zoomGesturesEnabled: interactive,
          style: widget.style,
        ),
        IgnorePointer(
          child: ValueListenableBuilder<bool>(
            valueListenable: _revealed,
            child: const ColoredBox(color: AppColors.mediumBackground),
            builder: (context, revealed, veil) => AnimatedOpacity(
              opacity: revealed ? 0 : 1,
              duration: MotionGuard.duration(context, AppMotion.medium),
              curve: AppMotion.signature,
              child: veil,
            ),
          ),
        ),
      ],
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
