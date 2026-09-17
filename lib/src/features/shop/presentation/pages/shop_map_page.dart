import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/jameia_map.dart';
import '../../domain/repositories/shop_repository.dart';

/// Jameia shop location map (`mach_pro_sailor_c_shop_map`, bundle 51) — 1:1 clone.
///
/// Full-screen real [JameiaMap] with a single shop pin (`JameiaAssets.shopMarker`)
/// + a user/destination pin (`JameiaAssets.deliveryUserMarker`), a floating
/// circular back button, and a pinned bottom card carrying the shop logo, name,
/// rating, address line, distance, and a "Directions" CTA that opens the
/// "navigate via" picker (Google / Apple / Baidu / Gaode).
///
/// GESTURE-SAFE (master doc §0.1 / §7): the [JameiaMap] platform view is NOT
/// `Positioned.fill` behind the tappable bottom card. The card is measured and
/// the map is sized to stop at its top, so the card's CTA always receives taps.
///
/// [Shop] has no street-address field, so the address line is composed from the
/// shop tags (its cuisine/category descriptors) + a static city label, matching
/// the Jameia map page that shows the merchant's category + locality under the pin.
class ShopMapPage extends StatefulWidget {
  const ShopMapPage({super.key, this.shopId = 's1'});

  /// Shop id resolved from the dummy repository (router passes the tapped id).
  final String shopId;

  @override
  State<ShopMapPage> createState() => _ShopMapPageState();
}

class _ShopMapPageState extends State<ShopMapPage> {
  // Bottom-card height, measured after first layout so the map box can stop at
  // the card's top edge (gesture-safe rule — never put the map behind the card).
  double _cardHeight = 0;
  final _cardKey = GlobalKey();

  // Real Jameia asset markers (loaded async). Until they decode we fall back to
  // the hue pins below so the map is never empty.
  Set<Marker>? _markers;

  late final Shop _shop;

  /// True when [ShopMapPage.shopId] matched no catalogue shop — the screen
  /// renders a not-found state instead of accessing the unset [_shop].
  bool _shopMissing = false;

  @override
  void initState() {
    super.initState();
    // Boundary read through the feature repository (this screen keeps the core
    // `Shop` DTO — no direct `JameiaRepository` reach-in).
    final shop = sl<ShopRepository>().shopById(widget.shopId);
    if (shop == null) {
      _shopMissing = true;
      return;
    }
    _shop = shop;
    _loadMarkers();
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
    if (!_shopMissing && _lastLocale != null && _lastLocale != locale) {
      _loadMarkers();
    }
    _lastLocale = locale;
  }

  void _measureCard() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final h = box?.size.height ?? 0;
    if (h > 0 && h != _cardHeight && mounted) {
      setState(() => _cardHeight = h);
    }
  }

  Future<void> _loadMarkers() async {
    final markers = await Future.wait([
      JameiaMap.assetMarker(
        'shop',
        _kShopLatLng,
        JameiaAssets.shopMarker,
        anchor: const Offset(0.5, 1.0),
        title: _shop.name,
      ),
      JameiaMap.assetMarker(
        'user',
        _kUserLatLng,
        JameiaAssets.deliveryUserMarker,
        anchor: const Offset(0.5, 1.0),
        title: 'map.marker_you'.tr(),
      ),
    ]);
    if (!mounted) return;
    setState(() => _markers = markers.toSet());
  }

  @override
  Widget build(BuildContext context) {
    if (_shopMissing) {
      return Scaffold(
        backgroundColor: AppColors.mediumBackground,
        body: ErrorView(onRetry: () => Navigator.maybePop(context)),
      );
    }
    final topPad = MediaQuery.paddingOf(context).top;

    // Fall back to colored hue pins while the real asset markers decode.
    final markers =
        _markers ??
        {
          JameiaMap.pin(
            'shop',
            _kShopLatLng,
            hue: BitmapDescriptor.hueRed,
            title: _shop.name,
          ),
          JameiaMap.pin(
            'user',
            _kUserLatLng,
            hue: BitmapDescriptor.hueAzure,
            title: 'map.marker_you'.tr(),
          ),
        };

    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: Stack(
        children: [
          // GESTURE-SAFE: map box sized to the region ABOVE the bottom card,
          // never Positioned.fill behind it. Until the card is measured we cover
          // the full screen (first frame only) so the map paints immediately.
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            bottom: _cardHeight,
            child: JameiaMap(
              target: _kShopLatLng,
              zoom: 15.0,
              markers: markers,
            ),
          ),
          // Floating circular back button (top-start, safe-area aware).
          PositionedDirectional(
            top: topPad + AppSpacing.s8,
            start: AppSpacing.s12,
            child: const _FloatingBack(),
          ),
          // Pinned bottom info card (measured for the gesture-safe map box).
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _ShopLocationCard(key: _cardKey, shop: _shop),
          ),
        ],
      ),
    );
  }
}

// ── Floating back button ──────────────────────────────────────────────────────

class _FloatingBack extends StatelessWidget {
  const _FloatingBack();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowInk10,
              blurRadius: 9,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s8),
          child: Icon(JameiaIcons.back, size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}

// Demo coords — Kuwait City center as the shop location (master doc §1.2 base),
// with the user pin offset slightly so both markers are visible.
const _kShopLatLng = LatLng(29.3759, 47.9774);
const _kUserLatLng = LatLng(29.3705, 47.9710);

// ── Bottom shop-location card ─────────────────────────────────────────────────

class _ShopLocationCard extends StatelessWidget {
  const _ShopLocationCard({super.key, required this.shop});
  final Shop shop;

  /// [Shop] has no street field — compose a plausible address from category tags.
  String get _addressLine {
    final tags = shop.tags
        .where((t) => t.trim().isNotEmpty)
        .take(2)
        .join(' · ');
    return tags.isEmpty
        ? 'map.fallback_address'.tr()
        : '$tags · ${'map.fallback_address'.tr()}';
  }

  void _openNavPicker(BuildContext context) {
    showJameiaBottomSheet<void>(
      context,
      builder: (sheetCtx) => _NavigateViaSheet(shop: shop),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.s16,
        end: AppSpacing.s16,
        top: AppSpacing.s16,
        bottom: AppSpacing.s16 + bottomPad,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(AppSize.r12),
          topEnd: Radius.circular(AppSize.r12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop identity row: logo + name + rating.
          Row(
            children: [
              JameiaImage.circle(url: shop.logo, size: 44),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RatingBadge(rating: shop.rating, count: shop.ratingCount),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          // Address line with a leading location glyph.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                JameiaIcons.location,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  _addressLine,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          // Distance row.
          Row(
            children: [
              const Icon(
                JameiaIcons.delivery,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'map.distance_from_you'.tr(
                  args: [Formatters.distance(shop.distanceKm)],
                ),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          // Directions CTA → "navigate via" picker.
          AppButton(
            label: 'map.directions'.tr(),
            onPressed: () => _openNavPicker(context),
            trailing: const Icon(
              JameiaIcons.arrowRight,
              size: 18,
              color: AppColors.brandForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Navigate via" picker bottom sheet ────────────────────────────────────────

/// One installable maps app: its display name, the deep-link template, and the
/// app-store fallback used when the scheme can't be opened. `{lat}` / `{lng}` /
/// `{name}` are substituted with the destination before launch.
///
/// Schemes are the canonical Jameia "navigate via" deep links (master doc §7
/// nav-scheme table extended with the CN map apps). No `url_launcher` dependency
/// in the project yet, so the launch is STUBBED with a [SnackBar] — the picker
/// UI + scheme/fallback data stay faithful for when the launcher is wired in.
class _MapApp {
  const _MapApp({
    required this.label,
    required this.icon,
    required this.scheme,
    required this.store,
  });

  /// i18n key for the app's display name (resolve with `label.tr()`).
  final String label;
  final IconData icon;

  /// Deep-link template (e.g. `comgooglemaps://?...`).
  final String scheme;

  /// App-store / web fallback when [scheme] can't be opened.
  final String store;

  String linkFor(LatLng dest, String name) => scheme
      .replaceAll('{lat}', '${dest.latitude}')
      .replaceAll('{lng}', '${dest.longitude}')
      .replaceAll('{name}', Uri.encodeComponent(name));
}

const _kMapApps = <_MapApp>[
  _MapApp(
    // i18n key — resolved via .tr() at the display/launch sites.
    label: 'map.google',
    icon: JameiaIcons.location,
    scheme: 'comgooglemaps://?daddr={lat},{lng}&directionsmode=driving',
    store: 'https://www.google.com/maps/dir/?api=1&destination={lat},{lng}',
  ),
  _MapApp(
    label: 'map.apple',
    icon: JameiaIcons.location,
    scheme: 'maps://?daddr={lat},{lng}&dirflg=d',
    store: 'http://maps.apple.com/?daddr={lat},{lng}',
  ),
  _MapApp(
    label: 'map.baidu',
    icon: JameiaIcons.location,
    scheme:
        'baidumap://map/direction?destination={lat},{lng}&mode=driving&coord_type=gcj02',
    store: 'https://map.baidu.com/?latlng={lat},{lng}',
  ),
  _MapApp(
    label: 'map.gaode',
    icon: JameiaIcons.location,
    scheme:
        'androidamap://navi?sourceApplication=Jameia&lat={lat}&lon={lng}&dev=0',
    store: 'https://uri.amap.com/navigation?to={lng},{lat}',
  ),
];

class _NavigateViaSheet extends StatelessWidget {
  const _NavigateViaSheet({required this.shop});
  final Shop shop;

  void _launch(BuildContext context, _MapApp app) {
    Navigator.pop(context);
    // STUB: no url_launcher in the project — surface the resolved deep link so
    // the picker is faithful and trivially wired to launchUrl() later.
    final link = app.linkFor(_kShopLatLng, shop.name);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${'map.open_in_maps'.tr()} · ${app.label.tr()}\n$link',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.s16,
          end: AppSpacing.s16,
          top: AppSpacing.s16,
          bottom: AppSpacing.s12 + bottomPad,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber.
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'map.open_in_maps'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (var i = 0; i < _kMapApps.length; i++) ...[
              if (i > 0) const ThinDivider(),
              _MapAppRow(
                app: _kMapApps[i],
                onTap: () => _launch(context, _kMapApps[i]),
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            AppButton(
              label: 'common.cancel'.tr(),
              color: AppColors.smallBackground,
              foreground: AppColors.primaryText,
              onPressed: () => Navigator.maybePop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapAppRow extends StatelessWidget {
  const _MapAppRow({required this.app, required this.onTap});
  final _MapApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            Icon(app.icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(app.label.tr(), style: AppTextStyles.bodyMedium),
            ),
            const Icon(
              JameiaIcons.arrowRightSmall,
              size: 16,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}
