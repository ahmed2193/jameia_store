import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/keeta_geocode.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/keeta_map.dart';
import '../../../../core/widgets/radio_dot.dart';

/// Result of [MapPickScreen] — the chosen delivery coordinate + resolved address.
class PickedLocation {
  const PickedLocation({
    required this.lat,
    required this.lng,
    required this.area,
    required this.line,
  });
  final double lat;
  final double lng;
  final String area;
  final String line;
}

/// KeeTa "العنوان / Address" map location-picker: a full-screen interactive map
/// with a FIXED BLACK centre pin, a floating address-label bubble above it, a
/// "Update location" recenter pill, and a bottom card carrying a radio list of
/// the 3 nearby address candidates + a Confirm CTA. Drag the map under the pin
/// and the candidates re-resolve on idle.
class MapPickScreen extends StatefulWidget {
  const MapPickScreen({super.key, this.initial});
  final LatLng? initial;

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  GoogleMapController? _controller;
  late LatLng _center;
  late List<({String title, String subtitle, LatLng pos})> _candidates;
  int _selected = 0;
  bool _moving = false;
  // True while the camera is animating to a candidate the user tapped — so the
  // idle handler keeps that selection instead of re-resolving from scratch.
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? KeetaGeocode.base;
    _candidates = KeetaGeocode.nearbyCandidates(_center);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onMove(CameraPosition pos) {
    _center = pos.target;
    if (!_moving) setState(() => _moving = true);
  }

  void _onIdle() {
    // A tap-driven move keeps the chosen candidate; only a manual drag
    // re-resolves the candidate list from the new centre.
    if (_programmatic) {
      _programmatic = false;
      setState(() => _moving = false);
      return;
    }
    setState(() {
      _moving = false;
      _candidates = KeetaGeocode.nearbyCandidates(_center);
      _selected = 0;
    });
  }

  /// Tapping a candidate in the bottom sheet slides the map (and the pin) to
  /// that candidate's coordinate.
  void _onSelect(int i) {
    setState(() {
      _selected = i;
      _moving = true;
    });
    _programmatic = true;
    _controller?.animateCamera(CameraUpdate.newLatLng(_candidates[i].pos));
  }

  Future<void> _recenter() async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(KeetaGeocode.base, 16),
    );
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        area: KeetaGeocode.reverse(_center).area,
        line: _candidates[_selected].title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: Stack(
        children: [
          // ── Interactive map ────────────────────────────────────────────────
          Positioned.fill(
            child: KeetaMap(
              target: _center,
              zoom: 16,
              onMapCreated: (c) => _controller = c,
              onCameraMove: _onMove,
              onCameraIdle: _onIdle,
            ),
          ),

          // ── Fixed centre pin + floating address-label bubble ───────────────
          // The pin tip sits on the geometric map centre; the bubble floats just
          // above the pin head.
          Center(
            child: _CenterMarker(
              raised: _moving,
              label: _candidates[_selected].title,
            ),
          ),

          // ── Top header: back chevron + search field ────────────────────────
          PositionedDirectional(
            top: topPad + AppSpacing.s8,
            start: AppSpacing.s12,
            end: AppSpacing.s12,
            child: const _TopBar(),
          ),

          // ── "Update location" recenter pill (bottom-start of the map) ──────
          PositionedDirectional(
            start: AppSpacing.s16,
            bottom: 236,
            child: _UpdatePill(onTap: _recenter),
          ),

          // ── Bottom card: helper + candidate radio list + Confirm CTA ───────
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _BottomCard(
              candidates: _candidates,
              selected: _selected,
              onSelect: _onSelect,
              onConfirm: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

/// The fixed map-centre marker: a black teardrop pin (filled circular head with
/// an inner white dot, on a short stem) with a white rounded LABEL BUBBLE
/// floating just above it. The whole assembly lifts a few px while panning.
class _CenterMarker extends StatelessWidget {
  const _CenterMarker({required this.raised, required this.label});
  final bool raised;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: MotionGuard.curve(context, AppMotion.standard),
      offset: Offset(0, raised ? -0.08 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating address-label bubble.
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.overlayDivider,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s6),

          // Black teardrop pin head (circle + inner white dot).
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Short stem down to the tip.
          Container(width: 2, height: 12, color: AppColors.black),

          // Ground shadow under the tip.
          AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: MotionGuard.curve(context, AppMotion.standard),
            width: raised ? 12 : 9,
            height: raised ? 5 : 4,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),

          // Spacer so the tip/shadow sit on the geometric centre.
          const SizedBox(height: 51),
        ],
      ),
    );
  }
}

/// Top white chrome: a circular back button beside a search stub field.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleBtn(
          icon: KeetaIcons.back,
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: AppSpacing.s12),
        const Expanded(child: _SearchStub()),
      ],
    );
  }
}

/// Visual-only search field — "Please enter the address" with a magnifier.
class _SearchStub extends StatelessWidget {
  const _SearchStub();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            KeetaIcons.search,
            size: 18,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: TextField(
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryText,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'map.search_address_hint'.tr(),
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White "Update location" pill — a recenter/target icon + label.
class _UpdatePill extends StatelessWidget {
  const _UpdatePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 2,
      shadowColor: AppColors.overlayDivider,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                KeetaIcons.location,
                size: 18,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.s6),
              Text(
                'map.update_location'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.overlayDivider,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}

/// Bottom sheet card: helper line + candidate radio list + Confirm CTA.
class _BottomCard extends StatelessWidget {
  const _BottomCard({
    required this.candidates,
    required this.selected,
    required this.onSelect,
    required this.onConfirm,
  });
  final List<({String title, String subtitle, LatLng pos})> candidates;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        bottomPad + AppSpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'map.driver_deliver_note'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          for (var i = 0; i < candidates.length; i++)
            _CandidateRow(
              title: candidates[i].title,
              subtitle: candidates[i].subtitle,
              selected: i == selected,
              onTap: () => onSelect(i),
            ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            label: 'map.confirm_delivery_location'.tr(),
            onPressed: onConfirm,
            radius: AppRadius.r3,
          ),
        ],
      ),
    );
  }
}

/// One candidate row: a radio circle (yellow dot when selected) + title +
/// subtitle. The selected row gets a subtle brandLightBg highlight.
class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Passive PressScale (no onTap) so the InkWell keeps its ripple.
    return PressScale(
      child: Material(
        color: selected ? AppColors.brandLightBg : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioDot(selected: selected),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

