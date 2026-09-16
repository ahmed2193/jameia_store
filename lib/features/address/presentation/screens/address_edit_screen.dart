import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/keeta_geocode.dart';
import '../../../../core/utils/keeta_location.dart';
import '../../../../core/utils/lbs_service.dart';
import '../../../../core/widgets/keeta_map.dart';
import '../cubit/address_edit_cubit.dart';
import '../widgets/address_edit/address_search_box.dart';
import '../widgets/address_edit/address_top_bar.dart';
import '../widgets/address_edit/center_marker.dart';
import '../widgets/address_edit/form_sheet.dart';
import '../widgets/address_edit/recenter_pill.dart';
import '../widgets/address_edit/select_sheet.dart';
import '../widgets/address_edit/suggestion_list.dart';
import '../widgets/address_edit/zoom_button.dart';

/// KeeTa `mach_pro_sailor_c_address_select_page` (C-PAGE v0.0.136) clone — the
/// unified address create / edit screen.
///
/// One continuous screen with two sheet stages over the SAME map (RE §3):
///   • SELECT — a draggable map sized to the region ABOVE the sheet (never
///     Positioned.fill behind it) with a fixed centre pin that reverse-geocodes
///     as the camera idles, a nearby/autocomplete candidate list that recenters
///     the pin, a search field, a "use my location" pill, a not-serviceable
///     banner, and a Confirm CTA.
///   • FORM — the map shrinks to ~top 30 % and a scrollable schema-driven form
///     appears: delivery-address summary (Edit → SELECT), struct-type tabs
///     (Apartment/House/Office), label picker, building/door/floor fields,
///     contact + +965 phone, drop-off + alt-location, note, and Save.
///
/// All user-facing strings are localized via easy_localization (`'key'.tr()`).
/// The SELECT candidate list + search are backed by the async [KeetaLbs] layer
/// (REAL Google Places, locale-aware, debounced + stale-guarded). Editing an
/// existing [KeetaAddress] (or re-opening one with a pin) jumps straight to FORM.
class AddressEditScreen extends StatelessWidget {
  const AddressEditScreen({super.key, this.address});

  /// The address being edited; `null` for "New address".
  final KeetaAddress? address;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressEditCubit>()..seed(address),
      child: _AddressEditView(isEdit: address != null),
    );
  }
}

class _AddressEditView extends StatefulWidget {
  const _AddressEditView({required this.isEdit});
  final bool isEdit;

  @override
  State<_AddressEditView> createState() => _AddressEditViewState();
}

class _AddressEditViewState extends State<_AddressEditView> {
  // ── Map-picker state ────────────────────────────────────────────────────────
  GoogleMapController? _map;
  late LatLng _center;
  late List<({String title, String subtitle, LatLng pos})> _candidates;
  int _selected = 0;
  bool _moving = false;
  // True while the camera animates to a tapped candidate / search result, so the
  // idle handler keeps that selection instead of re-resolving from scratch.
  bool _programmatic = false;
  // True when the programmatic move is a "Locate me" recenter (not a candidate
  // tap), so the idle handler refreshes the candidate list for the new centre.
  bool _programmaticRefresh = false;
  // false = SELECT (candidate list) sheet; true = FORM (address details) sheet.
  bool _confirmed = false;
  bool _serviceable = true;
  bool _outOfFence = false;

  // True while an async KeetaLbs.nearby() fetch is in flight — the SELECT sheet
  // dims the (stale) candidate list so it never looks frozen.
  bool _loadingNearby = false;
  // Stale-guard: bumped before every async nearby/search await. A late result
  // whose captured seq != the current seq is ignored.
  int _reqSeq = 0;
  // Debounce timers — fetch only after the camera idles / typing pauses ~350ms.
  Timer? _nearbyDebounce;
  Timer? _searchDebounce;
  // One-shot guard so the first locale-aware nearby() fetch runs once after the
  // first frame (context.locale isn't ready in initState).
  bool _didKickoff = false;

  // Search typeahead.
  late final TextEditingController _search;
  List<({String title, String subtitle, LatLng pos})> _suggestions = const [];

  // Inline FORM validation errors: field → i18n KEY. Populated on a failed Save,
  // cleared per-field as the user edits. Drives each field's InputDecoration.
  Map<AddrField, String> _errors = {};
  // True after the leave-at-spot alt-location requirement fails a Save tap.
  bool _altError = false;

  /// Current app language code for the LBS layer (Places/geocoder `language`).
  String get _localeId => context.locale.languageCode;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    final s = context.read<AddressEditCubit>().state;
    final hasPin = s.lat != 0.0 || s.lng != 0.0;
    // EDIT-LOAD: the cubit seeds lat/lng to KeetaGeocode.base for a NEW address
    // (non-zero), so lat/lng are used PURELY as the initial map centre here.
    _center = hasPin ? LatLng(s.lat, s.lng) : KeetaGeocode.base;
    // Seed with the SYNC offline candidates so the sheet renders immediately;
    // the REAL list arrives from the post-frame KeetaLbs.nearby() fetch.
    _candidates = KeetaGeocode.nearbyCandidates(_center);
    _serviceable = KeetaGeocode.isServiceable(_center);

    // FORM-FIRST FIX: gate the FORM stage ONLY on widget.isEdit. A NEW address
    // (lat/lng pre-seeded to base) must open in SELECT (map-pick); an existing
    // one jumps straight to FORM with its SAVED coordinate as the centre.
    if (widget.isEdit) _confirmed = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context.locale is ready here; kick the first REAL fetch once.
    if (!_didKickoff) {
      _didKickoff = true;
      if (!_confirmed) {
        // NEW address: open ON the device's current location (req 4) — move the
        // camera there first, then the idle handler resolves nearby at it.
        _goToCurrentLocation();
      }
    }
  }

  /// INITIAL LOCATION = CURRENT LOCATION (NEW address only): fetch the device
  /// GPS fix (falls back to base), smoothly animate the camera + fixed pin onto
  /// it at zoom 16, then resolve the REAL nearby candidates there. The existing
  /// loading state shows while the fix + nearby fetch are in flight.
  Future<void> _goToCurrentLocation() async {
    setState(() {
      _moving = true;
      _loadingNearby = true;
    });
    _programmatic = true;
    _programmaticRefresh = true; // new area → refresh the REAL candidate list.
    final pos = await KeetaLocation.current();
    if (!mounted) return;
    _center = pos;
    // Smooth move (animateCamera, never moveCamera). If the controller isn't
    // ready yet, fall back to a direct nearby fetch so we never hang.
    final map = _map;
    if (map != null) {
      await map.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    } else {
      _programmatic = false;
      _programmaticRefresh = false;
      if (!mounted) return;
      setState(() {
        _moving = false;
        _serviceable = KeetaGeocode.isServiceable(_center);
        _outOfFence = !KeetaGeocode.insideFence(_center);
      });
      _fetchNearby();
    }
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
  /// Fetch the selected point + its 2 nearest REAL places (Google Places),
  /// stale-guarded against newer requests. Pass [keepSelection] to preserve the
  /// current radio selection (e.g. after a candidate tap that already recentred).
  Future<void> _fetchNearby({bool keepSelection = false}) async {
    final seq = ++_reqSeq;
    final target = _center;
    setState(() => _loadingNearby = true);
    final results = await KeetaLbs.nearby(target, localeId: _localeId);
    if (!mounted || seq != _reqSeq) return; // a newer request superseded this.
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
        _serviceable = KeetaGeocode.isServiceable(_center);
        _outOfFence = !KeetaGeocode.insideFence(_center);
      });
      // A "Locate me" recenter lands on a brand-new area, so re-resolve the
      // REAL candidate list (RE §3.2: every idle re-runs nearbyAddress). A
      // candidate tap keeps the existing list + selection instead.
      if (refresh) _scheduleNearby();
      return;
    }
    if (_confirmed) return; // FORM mode: the map is frozen as a backdrop.
    setState(() {
      _moving = false;
      _serviceable = KeetaGeocode.isServiceable(_center);
      _outOfFence = !KeetaGeocode.insideFence(_center);
    });
    _scheduleNearby();
    if (_outOfFence) {
      _toast('addr.out_of_range'.tr());
    }
  }

  /// Debounce the async REAL nearby fetch (~350ms) after the camera idles.
  void _scheduleNearby() {
    _nearbyDebounce?.cancel();
    _nearbyDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted && !_confirmed) _fetchNearby();
    });
  }

  /// TAP-TO-PLACE: tapping (or long-pressing) the map in SELECT mode smoothly
  /// slides the camera + the fixed centre pin onto the tapped coordinate; the
  /// idle handler then re-resolves the REAL nearby list at that new point.
  void _onMapTap(LatLng p) {
    if (_confirmed) return; // FORM: the map is a frozen backdrop.
    FocusScope.of(context).unfocus();
    setState(() {
      _moving = true;
      _selected = 0;
      _suggestions = const [];
    });
    _programmatic = true;
    _programmaticRefresh = true; // new point → refresh the REAL candidate list.
    _center = p;
    _map?.animateCamera(CameraUpdate.newLatLng(p));
  }

  void _zoomIn() => _map?.animateCamera(CameraUpdate.zoomIn());

  void _zoomOut() => _map?.animateCamera(CameraUpdate.zoomOut());

  /// Tapping a candidate slides the map (and the fixed pin) to its coordinate.
  void _onSelectCandidate(int i) {
    setState(() {
      _selected = i;
      _moving = true;
    });
    _programmatic = true;
    _center = _candidates[i].pos;
    _map?.animateCamera(CameraUpdate.newLatLng(_candidates[i].pos));
  }

  // ── Search ──────────────────────────────────────────────────────────────────
  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    final query = q.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = const []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final seq = ++_reqSeq;
      final results = await KeetaLbs.search(
        query,
        localeId: _localeId,
        near: _center,
      );
      if (!mounted || seq != _reqSeq) return; // superseded by a newer request.
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
    _programmaticRefresh = true; // new area → refresh the REAL candidate list.
    _center = hit.pos;
    _map?.animateCamera(CameraUpdate.newLatLngZoom(hit.pos, 16));
  }

  /// SELECT → FORM: gate on serviceability, reverse-geocode the pin to REAL
  /// place values, pre-fill the form fields, then persist + grow the sheet.
  Future<void> _onConfirmLocation() async {
    if (!KeetaGeocode.isServiceable(_center)) {
      _toast('addr.outside_area'.tr());
      return;
    }
    final cubit = context.read<AddressEditCubit>();
    final r = await KeetaLbs.reverse(_center, localeId: _localeId);
    if (!mounted) return;
    // Persist the confirmed pin + REAL resolved area.
    cubit.setLocation(
      lat: _center.latitude,
      lng: _center.longitude,
      area: r.area,
    );
    // Pre-fill the schema fields from the resolved address (only when the
    // resolver returned a value, so existing user input is never wiped).
    if (r.area.isNotEmpty) cubit.setField(AddrField.area, r.area);
    if (r.street.isNotEmpty) cubit.setField(AddrField.street, r.street);
    if (r.building.isNotEmpty) {
      cubit.setField(AddrField.buildingName, r.building);
    }
    if (r.block.isNotEmpty) cubit.setField(AddrField.block, r.block);
    if (r.house.isNotEmpty) cubit.setField(AddrField.aptNumber, r.house);
    // Build the FORM sheet (its field controllers seed from the cubit state).
    setState(() => _confirmed = true);
  }

  /// FORM → SELECT: collapse back to the candidate list (the "X" / "Edit").
  void _backToSelect() {
    FocusScope.of(context).unfocus();
    setState(() {
      _confirmed = false;
      _moving = false;
      _selected = 0;
      _serviceable = KeetaGeocode.isServiceable(_center);
    });
    // Re-resolve the REAL nearby list for the (possibly re-confirmed) pin.
    _fetchNearby();
  }

  /// "Locate me": fetch the device GPS fix (falls back to base) and smoothly
  /// animate the camera + fixed pin onto it; the idle handler refreshes nearby.
  Future<void> _recenter() async {
    _programmatic = true;
    _programmaticRefresh = true; // recenter lands on a new area → refresh list.
    setState(() {
      _moving = true;
      _loadingNearby = true;
    });
    final pos = await KeetaLocation.current();
    if (!mounted) return;
    _center = pos;
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
  }

  Future<void> _save() async {
    final cubit = context.read<AddressEditCubit>();
    final errs = cubit.fieldErrors();
    final s = cubit.state;
    // Leave-at-spot also requires an alt-location (NOT an AddrField).
    final altMissing =
        s.dropOff == DropOff.leaveAtSpot && s.altLocation.trim().isEmpty;
    if (errs.isNotEmpty || altMissing) {
      setState(() {
        _errors = errs;
        _altError = altMissing;
      });
      _toast('addr.fix_errors'.tr());
      return;
    }
    setState(() {
      _errors = {};
      _altError = false;
    });
    final saved = await cubit.save();
    if (!mounted || saved == null) return;
    Navigator.pop(context, saved);
  }

  /// Clear a single field's inline error as the user edits it, so the red
  /// message disappears while typing (no-op when the field has no error).
  void _clearError(AddrField field) {
    if (_errors.containsKey(field)) {
      setState(() => _errors.remove(field));
    }
  }

  /// Clear the leave-at-spot alt-location error as the user types into it.
  void _clearAltError() {
    if (_altError) setState(() => _altError = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    final screenH = media.size.height;
    // SELECT: the map fills the area above the bottom sheet. FORM: the map keeps
    // only the top ~30 % (the form sheet covers the rest).
    final mapBottom = _confirmed ? screenH * 0.70 : _selectSheetHeight(context);

    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map — sized ONLY to the region above the sheet (gesture-safe;
          // never Positioned.fill behind a tappable sheet).
          AnimatedPositioned(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: MotionGuard.curve(context, AppMotion.signature),
            top: 0,
            left: 0,
            right: 0,
            bottom: mapBottom,
            child: Stack(
              children: [
                Positioned.fill(
                  child: KeetaMap(
                    target: _center,
                    zoom: 16,
                    interactive: !_confirmed,
                    onMapCreated: (c) => _map = c,
                    onCameraMove: _onMove,
                    onCameraIdle: _onIdle,
                    onTap: _onMapTap,
                    onLongPress: _onMapTap,
                  ),
                ),
                // Fixed centre pin — centred on the MAP region only.
                IgnorePointer(
                  child: Center(
                    child: CenterMarker(
                      raised: _moving,
                      label: _confirmed ? '' : _candidates[_selected].title,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Top chrome — leading circle + search field (SELECT) / title bar.
          PositionedDirectional(
            top: topPad + AppSpacing.s8,
            start: AppSpacing.s12,
            end: AppSpacing.s12,
            child: AddressTopBar(
              icon: _confirmed ? KeetaIcons.close : KeetaIcons.back,
              onLeading: _confirmed
                  ? _backToSelect
                  : () => Navigator.maybePop(context),
              search: _confirmed
                  ? null
                  : AddressSearchBox(
                      controller: _search,
                      onChanged: _onSearchChanged,
                    ),
            ),
          ),

          // 2b. Autocomplete dropdown (SELECT only, while typing).
          if (!_confirmed && _suggestions.isNotEmpty)
            PositionedDirectional(
              top: topPad + AppSpacing.s8 + 40 + AppSpacing.s8,
              start: AppSpacing.s12 + 40 + AppSpacing.s12,
              end: AppSpacing.s12,
              child: SuggestionList(
                items: _suggestions,
                onPick: _onPickSuggestion,
              ),
            ),

          // 3. "Locate me" recenter pill — SELECT mode only.
          if (!_confirmed)
            PositionedDirectional(
              end: AppSpacing.s16,
              bottom: _selectSheetHeight(context) + AppSpacing.s12,
              child: RecenterPill(onTap: _recenter),
            ),

          // 3b. Stacked zoom-in / zoom-out controls — sit above the recenter
          // pill, inside the map's tappable region (SELECT mode only).
          if (!_confirmed)
            PositionedDirectional(
              end: AppSpacing.s16,
              bottom: _selectSheetHeight(context) + AppSpacing.s12 + 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 'address_addresspage_zoomin'
                  ZoomButton(icon: Icons.add, onTap: _zoomIn),
                  const SizedBox(height: AppSpacing.s8),
                  // 'address_zoomout_Notification'
                  ZoomButton(icon: Icons.remove, onTap: _zoomOut),
                ],
              ),
            ),

          // 4. Bottom sheet — bounded Positioned (keeps the map's top area free of
          // a full-screen overlay so the platform map composites correctly).
          AnimatedPositioned(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: MotionGuard.curve(context, AppMotion.signature),
            left: 0,
            right: 0,
            bottom: 0,
            top: _confirmed ? screenH * 0.30 : null,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheet),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.overlayDivider,
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: _confirmed
                  ? FormSheet(
                      onEditLocation: _backToSelect,
                      onSave: _save,
                      errors: _errors,
                      altError: _altError,
                      onClearError: _clearError,
                      onClearAltError: _clearAltError,
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

  /// Approximate SELECT-sheet height (helper line + 3 candidate rows + CTA).
  double _selectSheetHeight(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final banner = _serviceable ? 0.0 : 48.0;
    return 300 + banner + bottomPad;
  }
}
