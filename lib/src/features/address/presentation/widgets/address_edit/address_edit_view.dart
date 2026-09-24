import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/jameia_geocode.dart';
import '../../../../../core/utils/jameia_location.dart';
import '../../../../../core/utils/lbs_service.dart';
import '../../../../../core/widgets/jameia_map.dart';
import '../../cubit/address_edit_cubit.dart';
import 'address_saving_absorber.dart';
import 'address_search_box.dart';
import 'address_top_bar.dart';
import 'center_marker.dart';
import 'form_sheet.dart';
import 'recenter_pill.dart';
import 'select_sheet.dart';
import 'suggestion_list.dart';
import 'zoom_button.dart';

/// The address create / edit screen body: two sheet stages over ONE map
/// (RE §3).
///   • SELECT — a draggable map above the sheet with a fixed centre pin that
///     reverse-geocodes as the camera idles, nearby / autocomplete candidates
///     (REAL Google Places through `JameiaLbs`, debounced + stale-guarded), a
///     "use my location" pill, zoom buttons and a Confirm CTA.
///   • FORM — the address form rises as a full-height sheet, leaving a small
///     gap under the status bar.
/// Editing an existing address opens straight on FORM at its saved pin.
class AddressEditView extends StatefulWidget {
  const AddressEditView({super.key, required this.isEdit});

  final bool isEdit;

  @override
  State<AddressEditView> createState() => _AddressEditViewState();
}

class _AddressEditViewState extends State<AddressEditView> {
  static const double _pinZoom = 16;
  static const Duration _debounce = Duration(milliseconds: 350);
  static const double _formSheetTopGap = AppSpacing.s12;
  static const double _searchBoxHeight = AppSize.s40;
  static const double _zoomStackOffset = AppSize.s48;
  static const double _selectSheetBaseHeight = AppSize.s300;
  static const double _notServiceableBannerHeight = AppSize.s48;
  static const double _sheetShadowBlur = AppSize.s16;
  static const Offset _sheetShadowOffset = Offset(0, -AppSize.s2);

  // ── Map-picker state ────────────────────────────────────────────────────────
  GoogleMapController? _map;
  late LatLng _center;
  late List<({String title, String subtitle, LatLng pos})> _candidates;
  int _selected = 0;
  bool _moving = false;
  // True while the camera animates to a tapped candidate / search result, so
  // the idle handler keeps that selection instead of re-resolving from scratch.
  bool _programmatic = false;
  // True when the programmatic move lands on a new area ("Locate me", a map
  // tap, a search pick), so the idle handler refreshes the candidate list.
  bool _programmaticRefresh = false;
  // false = SELECT (candidate list) sheet; true = FORM (address details) sheet.
  bool _confirmed = false;
  bool _serviceable = true;
  bool _outOfFence = false;

  // An async JameiaLbs.nearby() fetch is in flight — the SELECT sheet dims the
  // (stale) candidate list so it never looks frozen.
  bool _loadingNearby = false;
  // Stale guard: bumped before every async nearby / search await; a late
  // result whose captured seq != the current seq is ignored.
  int _reqSeq = 0;
  Timer? _nearbyDebounce;
  Timer? _searchDebounce;
  // The first locale-aware nearby() fetch runs once, after the first frame
  // (context.locale isn't ready in initState).
  bool _didKickoff = false;

  late final TextEditingController _search = TextEditingController();
  List<({String title, String subtitle, LatLng pos})> _suggestions = const [];

  /// Current app language code for the LBS layer (Places / geocoder).
  String get _localeId => context.locale.languageCode;

  @override
  void initState() {
    super.initState();
    final pin = context.read<AddressEditCubit>().state.draft.location;
    _center = LatLng(pin.lat, pin.lng);
    // Seed with the SYNC offline candidates so the sheet renders immediately;
    // the REAL list arrives from the post-frame JameiaLbs.nearby() fetch.
    _candidates = JameiaGeocode.nearbyCandidates(_center);
    _serviceable = JameiaGeocode.isServiceable(_center);
    // A NEW address opens on SELECT (map pick); an existing one jumps straight
    // to FORM with its saved pin as the centre.
    if (widget.isEdit) _confirmed = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didKickoff) return;
    _didKickoff = true;
    // NEW address: open ON the device's current location.
    if (!_confirmed) _goToCurrentLocation();
  }

  /// NEW address only: fetch the device GPS fix (falls back to base), animate
  /// the camera + fixed pin onto it, then resolve the REAL nearby candidates.
  Future<void> _goToCurrentLocation() async {
    setState(() {
      _moving = true;
      _loadingNearby = true;
    });
    _programmatic = true;
    _programmaticRefresh = true;
    final pos = await JameiaLocation.current();
    if (!mounted) return;
    _center = pos;
    final map = _map;
    if (map != null) {
      await map.animateCamera(CameraUpdate.newLatLngZoom(pos, _pinZoom));
      return;
    }
    // The controller isn't ready yet: resolve here so the sheet never hangs.
    _programmatic = false;
    _programmaticRefresh = false;
    setState(() {
      _moving = false;
      _serviceable = JameiaGeocode.isServiceable(_center);
      _outOfFence = !JameiaGeocode.insideFence(_center);
    });
    _fetchNearby();
  }

  @override
  void dispose() {
    _nearbyDebounce?.cancel();
    _searchDebounce?.cancel();
    _map?.dispose();
    _search.dispose();
    super.dispose();
  }

  // ── Async nearby (REAL places) ───────────────────────────────────────────────
  /// The selected point + its nearest REAL places, stale-guarded. Pass
  /// [keepSelection] to preserve the current radio selection.
  Future<void> _fetchNearby({bool keepSelection = false}) async {
    final seq = ++_reqSeq;
    final target = _center;
    setState(() => _loadingNearby = true);
    final results = await JameiaLbs.nearby(target, localeId: _localeId);
    if (!mounted || seq != _reqSeq) return;
    setState(() {
      _loadingNearby = false;
      _candidates = results;
      if (!keepSelection || _selected >= _candidates.length) _selected = 0;
    });
  }

  // ── Map callbacks ───────────────────────────────────────────────────────────
  void _onMove(CameraPosition pos) {
    _center = pos.target;
    if (!_moving) setState(() => _moving = true);
  }

  void _onIdle() {
    if (_programmatic) {
      _programmatic = false;
      final refresh = _programmaticRefresh;
      _programmaticRefresh = false;
      setState(() {
        _moving = false;
        _serviceable = JameiaGeocode.isServiceable(_center);
        _outOfFence = !JameiaGeocode.insideFence(_center);
      });
      if (refresh) _scheduleNearby();
      return;
    }
    if (_confirmed) return; // FORM: the map is a frozen backdrop.
    setState(() {
      _moving = false;
      _serviceable = JameiaGeocode.isServiceable(_center);
      _outOfFence = !JameiaGeocode.insideFence(_center);
    });
    _scheduleNearby();
    if (_outOfFence) showJameiaSnackBar(context, 'addr.out_of_range'.tr());
  }

  void _scheduleNearby() {
    _nearbyDebounce?.cancel();
    _nearbyDebounce = Timer(_debounce, () {
      if (mounted && !_confirmed) _fetchNearby();
    });
  }

  /// Tap-to-place: slides the camera + fixed pin onto the tapped point.
  void _onMapTap(LatLng point) {
    if (_confirmed) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _moving = true;
      _selected = 0;
      _suggestions = const [];
    });
    _programmatic = true;
    _programmaticRefresh = true;
    _center = point;
    _map?.animateCamera(CameraUpdate.newLatLng(point));
  }

  void _zoomIn() => _map?.animateCamera(CameraUpdate.zoomIn());

  void _zoomOut() => _map?.animateCamera(CameraUpdate.zoomOut());

  void _onSelectCandidate(int index) {
    setState(() {
      _selected = index;
      _moving = true;
    });
    _programmatic = true;
    _center = _candidates[index].pos;
    _map?.animateCamera(CameraUpdate.newLatLng(_candidates[index].pos));
  }

  // ── Search ──────────────────────────────────────────────────────────────────
  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = const []);
      return;
    }
    _searchDebounce = Timer(_debounce, () async {
      final seq = ++_reqSeq;
      final results = await JameiaLbs.search(
        query,
        localeId: _localeId,
        near: _center,
      );
      if (!mounted || seq != _reqSeq) return;
      setState(() => _suggestions = results);
    });
  }

  void _onPickSuggestion(({String title, String subtitle, LatLng pos}) hit) {
    FocusScope.of(context).unfocus();
    _search.clear();
    setState(() {
      _suggestions = const [];
      _moving = true;
      _selected = 0;
    });
    _programmatic = true;
    _programmaticRefresh = true;
    _center = hit.pos;
    _map?.animateCamera(CameraUpdate.newLatLngZoom(hit.pos, _pinZoom));
  }

  /// SELECT → FORM: gate on serviceability, reverse-geocode the pin and let
  /// the resolved parts pre-fill the form, then grow the sheet.
  Future<void> _onConfirmLocation() async {
    if (!JameiaGeocode.isServiceable(_center)) {
      showJameiaSnackBar(context, 'addr.outside_area'.tr());
      return;
    }
    final cubit = context.read<AddressEditCubit>();
    final resolved = await JameiaLbs.reverse(_center, localeId: _localeId);
    if (!mounted) return;
    cubit.pinConfirmed(
      GeoPointEntity(lat: _center.latitude, lng: _center.longitude),
      city: resolved.area,
      block: resolved.block,
      street: resolved.street,
      building: resolved.building,
      apartment: resolved.house,
    );
    // The FORM fields seed their text from the cubit when they are built.
    setState(() => _confirmed = true);
  }

  /// FORM → SELECT: back to the candidate list (the "X" / "Edit").
  void _backToSelect() {
    FocusScope.of(context).unfocus();
    setState(() {
      _confirmed = false;
      _moving = false;
      _selected = 0;
      _serviceable = JameiaGeocode.isServiceable(_center);
    });
    _fetchNearby();
  }

  /// "Locate me": the device GPS fix (falls back to base); the idle handler
  /// refreshes nearby.
  Future<void> _recenter() async {
    _programmatic = true;
    _programmaticRefresh = true;
    setState(() {
      _moving = true;
      _loadingNearby = true;
    });
    final pos = await JameiaLocation.current();
    if (!mounted) return;
    _center = pos;
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(pos, _pinZoom));
  }

  /// Approximate SELECT-sheet height (helper line + 3 candidate rows + CTA).
  /// Uses the view padding, which stays put while the keyboard is open.
  double _selectSheetHeight(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final banner = _serviceable ? 0.0 : _notServiceableBannerHeight;
    return _selectSheetBaseHeight + banner + bottomPad;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final formTop = topPad + _formSheetTopGap;
    final selectSheetHeight = _selectSheetHeight(context);

    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map — sized to the region above the SELECT sheet (gesture-safe).
          // The FORM sheet covers it, so switching stages never resizes the
          // native map.
          AnimatedPositioned(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: MotionGuard.curve(context, AppMotion.signature),
            top: 0,
            left: 0,
            right: 0,
            bottom: selectSheetHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: JameiaMap(
                    target: _center,
                    zoom: _pinZoom,
                    interactive: !_confirmed,
                    onMapCreated: (controller) => _map = controller,
                    onCameraMove: _onMove,
                    onCameraIdle: _onIdle,
                    onTap: _onMapTap,
                    onLongPress: _onMapTap,
                  ),
                ),
                if (!_confirmed)
                  IgnorePointer(
                    child: Center(
                      child: CenterMarker(
                        raised: _moving,
                        label: _candidates[_selected].title,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Top chrome — back + search field (SELECT only; the FORM sheet
          // has its own header).
          if (!_confirmed)
            PositionedDirectional(
              top: topPad + AppSpacing.s8,
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              child: AddressTopBar(
                icon: JameiaIcons.back,
                onLeading: () => Navigator.maybePop(context),
                search: AddressSearchBox(
                  controller: _search,
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

          // 2b. Autocomplete dropdown (SELECT only, while typing).
          if (!_confirmed && _suggestions.isNotEmpty)
            PositionedDirectional(
              top: topPad + AppSpacing.s8 + _searchBoxHeight + AppSpacing.s8,
              start: AppSpacing.s12 + _searchBoxHeight + AppSpacing.s12,
              end: AppSpacing.s12,
              child: SuggestionList(
                items: _suggestions,
                onPick: _onPickSuggestion,
              ),
            ),

          // 3. "Locate me" + zoom controls — SELECT only.
          if (!_confirmed)
            PositionedDirectional(
              end: AppSpacing.s16,
              bottom: selectSheetHeight + AppSpacing.s12,
              child: RecenterPill(onTap: _recenter),
            ),
          if (!_confirmed)
            PositionedDirectional(
              end: AppSpacing.s16,
              bottom: selectSheetHeight + AppSpacing.s12 + _zoomStackOffset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ZoomButton(icon: Icons.add, onTap: _zoomIn),
                  const SizedBox(height: AppSpacing.s8),
                  ZoomButton(icon: Icons.remove, onTap: _zoomOut),
                ],
              ),
            ),

          // 4. FORM: the gap above the full-height sheet shows the page
          // background, not a sliver of the map under the status bar.
          if (_confirmed)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: formTop,
              child: const ColoredBox(color: AppColors.mediumBackground),
            ),

          // 5. Bottom sheet — a bounded Positioned, so the platform map above
          // it composites correctly.
          AnimatedPositioned(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: MotionGuard.curve(context, AppMotion.signature),
            left: 0,
            right: 0,
            bottom: 0,
            top: _confirmed ? formTop : null,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheet),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.overlayDivider,
                    blurRadius: _sheetShadowBlur,
                    offset: _sheetShadowOffset,
                  ),
                ],
              ),
              child: _confirmed
                  ? AddressSavingAbsorber(
                      child: FormSheet(
                        isEdit: widget.isEdit,
                        onEditLocation: _backToSelect,
                      ),
                    )
                  : SelectSheet(
                      candidates: _candidates,
                      selected: _selected,
                      serviceable: _serviceable,
                      loading: _loadingNearby,
                      onSelect: _onSelectCandidate,
                      onConfirm: _onConfirmLocation,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
