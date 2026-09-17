import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/utils/jameia_geocode.dart';
import '../../../../../core/widgets/jameia_map.dart';
import '../../../domain/entities/order.dart';
import 'circle_back_button.dart';
import 'eta_bubble.dart';

// ── Live map ──────────────────────────────────────────────────────────────────

// Demo coords — Kuwait City base + delivery route.
const _kShopLatLng = LatLng(29.3759, 47.9774);
const _kUserLatLng = LatLng(29.3861, 47.9899);
const _kRiderLatLng = LatLng(29.3810, 47.9836);

class MapHero extends StatefulWidget {
  const MapHero({super.key, required this.order});
  final OrderEntity order;

  @override
  State<MapHero> createState() => _MapHeroState();
}

class _MapHeroState extends State<MapHero> {
  // Real Jameia asset markers (shop / user / rider). Until they decode we fall
  // back to the generic hue pins so the map is never empty.
  Set<Marker>? _assetMarkers;

  // Fallback hue pins — used while the real asset markers load.
  Set<Marker> get _fallbackMarkers => {
    JameiaMap.pin(
      'shop',
      _kShopLatLng,
      hue: BitmapDescriptor.hueOrange,
      title: 'map.marker_shop'.tr(),
    ),
    JameiaMap.pin(
      'rider',
      _kRiderLatLng,
      hue: BitmapDescriptor.hueAzure,
      title: 'map.marker_rider'.tr(),
    ),
    JameiaMap.pin(
      'user',
      _kUserLatLng,
      hue: BitmapDescriptor.hueRed,
      title: 'map.marker_you'.tr(),
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  /// Locale at the last dependency change — detects a live language switch so the
  /// imperatively-built GoogleMap marker titles re-localize. Static `.tr()` text
  /// rebuilds via easy_localization, but these markers are cached in state.
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    if (_lastLocale != null && _lastLocale != locale) _loadMarkers();
    _lastLocale = locale;
  }

  @override
  void didUpdateWidget(covariant MapHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-load markers when the order (and thus rider/vehicle/heading) changes.
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.rider?.vehicle != widget.order.rider?.vehicle ||
        oldWidget.order.riderHeading != widget.order.riderHeading) {
      _loadMarkers();
    }
  }

  Future<void> _loadMarkers() async {
    final order = widget.order;
    // Cars use the pre-rendered 24-frame heading sprite (already drawn for the
    // heading → rotateBitmap:false); motorbikes are a single frame we rotate on
    // the map (rotateBitmap:true). Matches order_map_screen + RE §8.
    final isCar = order.rider?.vehicle == 'car';
    final riderAsset = isCar
        ? JameiaAssets.carMarkerForHeading(order.riderHeading)
        : JameiaAssets.riderMarkerMotorbike;
    final markers = await Future.wait([
      JameiaMap.assetMarker(
        'shop',
        _kShopLatLng,
        JameiaAssets.shopMarker,
        anchor: const Offset(0.5, 1.0),
        title: 'map.marker_shop'.tr(),
      ),
      JameiaMap.assetMarker(
        'user',
        _kUserLatLng,
        JameiaAssets.deliveryUserMarker,
        anchor: const Offset(0.5, 1.0),
        title: 'map.marker_you'.tr(),
      ),
      JameiaMap.headingMarker(
        'rider',
        _kRiderLatLng,
        riderAsset,
        order.riderHeading,
        rotateBitmap: !isCar,
      ),
    ]);
    if (!mounted) return;
    setState(() => _assetMarkers = markers.toSet());
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final topPad = MediaQuery.paddingOf(context).top;

    final markers = _assetMarkers ?? _fallbackMarkers;

    // Real ordered route shop → rider → user (bent so it reads as a road path),
    // matching order_map_screen + RE §8 (primary, width 4).
    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: JameiaGeocode.routePolyline(
          _kShopLatLng,
          _kRiderLatLng,
          _kUserLatLng,
        ),
        color: AppColors.primary,
        width: 4,
      ),
    };

    // GESTURE-SAFE LAYOUT (RE §0.1): the ETA bubble is tappable (opens the
    // map-app picker), so the GoogleMap must NOT sit full-bleed behind it — the
    // Android platform view would eat the tap. We size the live map to the
    // region ABOVE the bubble band, and lay the bubble out as a sibling below.
    const double bubbleBand =
        46 + AppSpacing.s12 + AppSpacing.s12; // bubble + gaps
    final double mapHeight = 320 + topPad - bubbleBand;

    return SizedBox(
      height: 320 + topPad,
      child: Column(
        children: [
          // Live map region — only the area above the ETA bubble.
          SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: JameiaMap(
                    target: _kRiderLatLng,
                    zoom: 14.0,
                    markers: markers,
                    polylines: polylines,
                  ),
                ),
                // Floating circular back button — inside the map box (non-
                // tappable map area below it), above the platform view.
                PositionedDirectional(
                  top: topPad + AppSpacing.s8,
                  start: AppSpacing.s12,
                  child: const CircleBackButton(),
                ),
              ],
            ),
          ),
          // ETA bubble — sibling BELOW the map box so its tap is never consumed
          // by the GoogleMap platform view.
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.pageMargin,
              end: AppSpacing.pageMargin,
              top: AppSpacing.s12,
              bottom: AppSpacing.s12,
            ),
            child: EtaBubble(order: order),
          ),
        ],
      ),
    );
  }
}
