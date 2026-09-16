import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/keeta_geocode.dart';
import '../../../../../core/widgets/keeta_map.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_address.dart';
import 'bottom_card.dart';
import 'circle_fab.dart';
import 'drop_off_sheet.dart';
import 'map_back_button.dart';
import 'map_eta_bubble.dart';
import 'map_picker_dialog.dart';
import 'nps_card.dart';
import 'recenter_button.dart';
import 'weather_banner.dart';

// Demo coords — Kuwait City base + delivery route. Shop at the base, the user a
// short hop NE, the rider walking the route between them.
const _kShopLatLng = LatLng(29.3759, 47.9774);
const _kUserLatLng = LatLng(29.3861, 47.9899);

class OrderMapLoaded extends StatefulWidget {
  const OrderMapLoaded({super.key, required this.order, required this.address});

  final OrderEntity order;
  final OrderAddressEntity address;

  @override
  State<OrderMapLoaded> createState() => _OrderMapLoadedState();
}

class _OrderMapLoadedState extends State<OrderMapLoaded> {
  /// Local drop-off preference (seeded from the dummy order, toggled in-sheet).
  late String _dropOff = widget.order.dropOffMethod;

  /// Dismissible bad-weather banner (active orders only).
  bool _showWeather = true;

  /// Dismissible post-delivery NPS card.
  bool _showNps = true;

  /// Real KeeTa asset markers, loaded asynchronously (null until ready — we fall
  /// back to hue pins so the map is never empty during the async decode).
  Set<Marker>? _markers;

  /// Map controller — used to recenter on the rider.
  GoogleMapController? _mapController;

  /// Measured bottom-card height so the map box stops exactly at its top edge
  /// (gesture-safe: no GoogleMap behind the tappable card).
  final GlobalKey _cardKey = GlobalKey();
  double _cardHeight = _kBottomCardReserve;

  /// The full route polyline (shop → rider → user) from the offline LBS.
  late List<LatLng> _route = KeetaGeocode.routePolyline(
    _kShopLatLng,
    _riderLatLngFor(widget.order),
    _kUserLatLng,
  );

  /// Live rider position + heading, advanced by a local simulation walking the
  /// route while the order is active (the cubit's own sim advances statusStep).
  late LatLng _riderPos = _riderLatLngFor(widget.order);
  late int _riderHeading = widget.order.riderHeading;
  Timer? _riderTimer;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _startRiderSimulation();
    // Measure the bottom card once after first layout — NOT on every rebuild
    // (the rider simulation rebuilds every 2s; the card height is stable).
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCard());
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
  void didUpdateWidget(covariant OrderMapLoaded oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order != widget.order) {
      _loadMarkers();
      _startRiderSimulation();
    }
  }

  @override
  void dispose() {
    _riderTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Deterministic starting rider coordinate — a point along the shop→user line
  /// nudged by the order's seed so each order's rider starts somewhere distinct.
  static LatLng _riderLatLngFor(OrderEntity order) {
    final t = 0.35 + (order.riderHeading % 60) / 200; // 0.35–0.65
    return LatLng(
      _kShopLatLng.latitude +
          (_kUserLatLng.latitude - _kShopLatLng.latitude) * t,
      _kShopLatLng.longitude +
          (_kUserLatLng.longitude - _kShopLatLng.longitude) * t,
    );
  }

  Future<void> _loadMarkers() async {
    final order = widget.order;
    // The rider marker is HEADING-ROTATED: the car asset is a pre-rendered
    // 24-frame set (15° step) picked by heading → rotateBitmap:false; the
    // single-frame motorbike marker is rotated on the map → rotateBitmap:true.
    final isCar = order.rider?.vehicle == 'car';
    final results = await Future.wait([
      KeetaMap.assetMarker(
        'shop',
        _kShopLatLng,
        KeetaAssets.shopMarker,
        anchor: const Offset(0.5, 1.0),
        title: 'map.marker_shop'.tr(),
      ),
      KeetaMap.assetMarker(
        'user',
        _kUserLatLng,
        KeetaAssets.deliveryUserMarker,
        anchor: const Offset(0.5, 1.0),
        title: 'map.marker_you'.tr(),
      ),
      KeetaMap.headingMarker(
        'rider',
        _riderPos,
        isCar
            ? KeetaAssets.carMarkerForHeading(_riderHeading)
            : KeetaAssets.riderMarkerMotorbike,
        _riderHeading,
        rotateBitmap: !isCar,
      ),
    ]);
    if (!mounted) return;
    setState(() => _markers = results.toSet());
  }

  /// Rebuild only the rider marker as it advances along the route (cheaper than
  /// reloading shop/user each tick).
  Future<void> _refreshRiderMarker() async {
    final order = widget.order;
    final isCar = order.rider?.vehicle == 'car';
    final rider = await KeetaMap.headingMarker(
      'rider',
      _riderPos,
      isCar
          ? KeetaAssets.carMarkerForHeading(_riderHeading)
          : KeetaAssets.riderMarkerMotorbike,
      _riderHeading,
      rotateBitmap: !isCar,
    );
    if (!mounted) return;
    final base = _markers;
    if (base == null) return;
    setState(() {
      _markers = {...base.where((m) => m.markerId.value != 'rider'), rider};
    });
  }

  // ── Live rider simulation ───────────────────────────────────────────────────
  // Walks [_riderPos] forward along the route polyline toward the user while the
  // order is active. This is the screen's local motion layer; the cubit keeps
  // owning the statusStep simulation.
  int _routeIdx = 0;

  void _startRiderSimulation() {
    _riderTimer?.cancel();
    _route = KeetaGeocode.routePolyline(_kShopLatLng, _riderPos, _kUserLatLng);
    _routeIdx = 0;
    if (!widget.order.isActive) return;
    _riderTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _riderTick(),
    );
  }

  void _riderTick() {
    if (!mounted) return;
    if (_routeIdx >= _route.length - 1) {
      _riderTimer?.cancel();
      return;
    }
    final from = _riderPos;
    final to = _route[_routeIdx + 1];
    _routeIdx++;
    _riderPos = to;
    _riderHeading = _headingBetween(from, to);
    _refreshRiderMarker();
  }

  /// Compass bearing (degrees, snapped to the 15° asset grid) from [a] to [b].
  static int _headingBetween(LatLng a, LatLng b) {
    final dLat = b.latitude - a.latitude;
    final dLng = b.longitude - a.longitude;
    var deg = (90 - math.atan2(dLat, dLng) * 180 / math.pi) % 360;
    if (deg < 0) deg += 360;
    return ((deg / 15).round() * 15) % 360;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _recenter() {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_riderPos, 14.0));
  }

  // ── Drop-off toggle sheet ───────────────────────────────────────────────────
  void _openDropOffSheet() {
    showKeetaBottomSheet<void>(
      context,
      builder: (sheetCtx) => DropOffSheet(
        current: _dropOff,
        onSelect: (method) {
          Navigator.pop(sheetCtx);
          if (method == _dropOff) return;
          setState(() => _dropOff = method);
          _toast(
            method == 'hand_to_me'
                ? 'dropoff.hand_to_me'.tr()
                : 'dropoff.leave_spot'.tr(),
          );
        },
      ),
    );
  }

  // ── Map-app picker dialog ───────────────────────────────────────────────────
  void _openMapPicker() {
    showKeetaDialog<void>(
      context,
      barrierLabel: 'map.open_in_maps'.tr(),
      pageBuilder: (dialogCtx) => MapPickerDialog(
        onPick: (label) {
          Navigator.pop(dialogCtx);
          _toast('map.opening_app'.tr(args: [label]));
        },
      ),
    );
  }

  /// After first/last layout, measure the bottom card so the map box height is
  /// exact (keeps the GoogleMap strictly above the tappable card).
  void _measureCard() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final h = box?.size.height;
    if (h != null && (h - _cardHeight).abs() > 0.5) {
      setState(() => _cardHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final address = widget.address;
    final topPad = MediaQuery.paddingOf(context).top;
    final delivered = order.statusStep >= 5;

    // Real KeeTa asset markers once loaded; hue pins as a fallback so the map is
    // never empty during the async decode.
    final markers =
        _markers ??
        {
          KeetaMap.pin(
            'shop',
            _kShopLatLng,
            hue: BitmapDescriptor.hueOrange,
            title: 'map.marker_shop'.tr(),
          ),
          KeetaMap.pin(
            'rider',
            _riderPos,
            hue: BitmapDescriptor.hueAzure,
            title: 'map.marker_rider'.tr(),
          ),
          KeetaMap.pin(
            'user',
            _kUserLatLng,
            hue: BitmapDescriptor.hueRed,
            title: 'map.marker_you'.tr(),
          ),
        };

    // Route polyline (RE §8: primary colour, width 4).
    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _route,
        color: AppColors.primary,
        width: 4,
      ),
    };

    return Stack(
      children: [
        // GESTURE-SAFE: the map fills only the region ABOVE the bottom card —
        // never Positioned.fill behind the tappable card (RE §0.1).
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: _cardHeight,
          child: KeetaMap(
            target: _riderPos,
            zoom: 14.0,
            markers: markers,
            polylines: polylines,
            onMapCreated: (c) => _mapController = c,
          ),
        ),

        // Floating circular back button (top-start).
        PositionedDirectional(
          top: topPad + AppSpacing.s8,
          start: AppSpacing.s12,
          child: const MapBackButton(),
        ),

        // Floating ETA bubble (top-centre) — h46 r16 (RE §2.2).
        if (!delivered)
          Positioned(
            top: topPad + AppSpacing.s8,
            left: 0,
            right: 0,
            child: Center(child: MapEtaBubble(order: order)),
          ),

        // Bad-weather banner for active orders (below the ETA bubble).
        if (_showWeather && order.isActive)
          PositionedDirectional(
            top: topPad + AppSpacing.s8 + 46 + AppSpacing.s8,
            start: AppSpacing.s12,
            end: AppSpacing.s12,
            child: WeatherBanner(
              onClose: () => setState(() => _showWeather = false),
            ),
          ),

        // Open-in-maps FAB (above the re-center FAB), pinned over the card top.
        PositionedDirectional(
          end: AppSpacing.s12,
          bottom: _cardHeight + AppSpacing.s12 + 52,
          child: CircleFab(icon: Icons.map_outlined, onTap: _openMapPicker),
        ),

        // Re-center FAB pinned just above the bottom card.
        PositionedDirectional(
          end: AppSpacing.s12,
          bottom: _cardHeight + AppSpacing.s12,
          child: RecenterButton(onTap: _recenter),
        ),

        // Post-delivery NPS card (floating, above the bottom card).
        if (delivered && _showNps)
          PositionedDirectional(
            start: AppSpacing.s12,
            end: AppSpacing.s12,
            bottom: _cardHeight + AppSpacing.s12,
            child: NpsCard(
              onRate: (_) {
                setState(() => _showNps = false);
                _toast('map.feedback_thanks'.tr());
              },
              onClose: () => setState(() => _showNps = false),
            ),
          ),

        // Bottom card: ETA + rider row + call / chat + fee + drop-off.
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: BottomCard(
            key: _cardKey,
            order: order,
            address: address,
            dropOff: _dropOff,
            onTapDropOff: _openDropOffSheet,
          ),
        ),
      ],
    );
  }
}

/// Fallback reserve height used for the very first frame before the bottom card
/// is measured (avoids a one-frame map-behind-card overlap).
const double _kBottomCardReserve = 220;
