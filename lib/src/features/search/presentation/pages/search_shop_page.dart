import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/entities/shop_sort.dart';
import '../cubit/search_cubit.dart';
import '../util/product_boundary.dart';
import '../widgets/delivery_pickup_tabs.dart';
import '../widgets/jameia_search_bar.dart';
import '../widgets/result_filter_bar.dart';
import '../widgets/shop_result_card.dart';

/// Jameia search results (`c_search_shop`) — committed-query pill bar +
/// Delivery/Pickup tabs + a horizontal filter row + an optional promo strip,
/// over a list of shop-with-products cards. Reads matching shops (+ their
/// products) from [SearchCubit]; sort/free-delivery live in the cubit, while
/// the Offers / Under-30 / mode filters are applied locally.
class SearchShopPage extends StatelessWidget {
  const SearchShopPage({super.key, this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchCubit>()..startResults(query),
      child: _ResultsView(query: query),
    );
  }
}

class _ResultsView extends StatefulWidget {
  const _ResultsView({required this.query});
  final String query;

  @override
  State<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<_ResultsView> {
  int _mode = 0; // 0 = Delivery, 1 = Pickup
  bool _offersOnly = false;
  bool _under30 = false;

  void _openShop(String shopId) => context.push(Routes.shop, extra: shopId);

  // TODO(P2.9-boundary): product_details is a separate feature whose screen
  // contract is the core `Product` DTO — rebuild it losslessly from our entity
  // (see util/product_boundary.dart) rather than leaking a search entity
  // across the feature seam.
  void _openProduct(ProductEntity p) =>
      context.push(Routes.productDetail, extra: p.toModel());

  static int _mins(String label) {
    final m = RegExp(r'\d+').firstMatch(label);
    return m == null ? 1 << 30 : int.parse(m.group(0)!);
  }

  List<ShopEntity> _applyLocal(List<ShopEntity> shops, ShopSort sort) {
    var list = shops;
    if (_offersOnly) {
      list = list
          .where(
            (s) => s.promo.isNotEmpty || s.products.any((p) => p.hasDiscount),
          )
          .toList(growable: false);
    }
    if (_under30) {
      list = list
          .where((s) => _mins(s.deliveryTime) <= 30)
          .toList(growable: false);
    }
    // Pickup defaults to nearest-first, but an explicit sort chip (rating /
    // distance / …) is honored via the cubit's own ordering.
    if (_mode == 1 && sort == ShopSort.recommended) {
      list = [...list]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return list;
  }

  Future<void> _openSortSheet() async {
    final cubit = context.read<SearchCubit>();
    final current = cubit.state.sort;
    final chosen = await showModalBottomSheet<ShopSort>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in ShopSort.values)
              ListTile(
                title: Text('search.${s.labelKey}'.tr()),
                trailing: s == current
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryText,
                      )
                    : null,
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) cubit.setSort(chosen);
  }

  List<ResultChipData> _deliveryChips(SearchState s) => [
    ResultChipData(
      label: 'search.sort_by'.tr(),
      dropdown: true,
      separatorAfter: true,
      onTap: _openSortSheet,
    ),
    ResultChipData(
      label: 'search.free_delivery'.tr(),
      icon: Icons.delivery_dining_rounded,
      selected: s.freeOnly,
      onTap: () => context.read<SearchCubit>().toggleFreeOnly(),
    ),
    ResultChipData(
      label: 'search.offers'.tr(),
      icon: Icons.local_offer_outlined,
      selected: _offersOnly,
      onTap: () => setState(() => _offersOnly = !_offersOnly),
    ),
    ResultChipData(
      label: 'search.under_30'.tr(),
      selected: _under30,
      onTap: () => setState(() => _under30 = !_under30),
    ),
  ];

  List<ResultChipData> _pickupChips() => [
    ResultChipData(
      label: 'search.sort_by'.tr(),
      dropdown: true,
      separatorAfter: true,
      onTap: _openSortSheet,
    ),
    ResultChipData(
      label: 'search.offers'.tr(),
      icon: Icons.local_offer_outlined,
      selected: _offersOnly,
      onTap: () => setState(() => _offersOnly = !_offersOnly),
    ),
    ResultChipData(
      label: 'search.sort_distance'.tr(),
      dropdown: true,
      onTap: () => context.read<SearchCubit>().setSort(ShopSort.distance),
    ),
    ResultChipData(
      label: 'search.sort_rating'.tr(),
      dropdown: true,
      onTap: () => context.read<SearchCubit>().setSort(ShopSort.rating),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          ResultsSearchBar(
            query: widget.query,
            onBack: () => Navigator.maybePop(context),
            onTapField: () => Navigator.maybePop(context),
            onClear: () => Navigator.maybePop(context),
          ),
          DeliveryPickupTabs(
            index: _mode,
            onChanged: (i) => setState(() => _mode = i),
          ),
          BlocBuilder<SearchCubit, SearchState>(
            builder: (context, s) => ResultFilterBar(
              chips: _mode == 0 ? _deliveryChips(s) : _pickupChips(),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              buildWhen: (p, c) =>
                  p.results != c.results || p.status != c.status,
              builder: (context, s) {
                if (s.status == SearchStatus.initial ||
                    s.status == SearchStatus.loading) {
                  return const SizedBox.shrink();
                }
                final shops = _applyLocal(s.results, s.sort);
                if (shops.isEmpty) {
                  return EmptyStateView(
                    icon: JameiaIcons.search,
                    message: 'search.no_results_for'.tr(
                      namedArgs: {'query': widget.query.trim()},
                    ),
                  );
                }
                return ContentClamp(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                    itemCount: shops.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return _PromoStrip(shops: shops);
                      final shop = shops[i - 1];
                      return RepaintBoundary(
                        child: StaggerEntrance(
                          index: i - 1,
                          child: ShopResultCard(
                            shop: shop,
                            pickup: _mode == 1,
                            onOpenShop: _openShop,
                            onOpenProduct: _openProduct,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Light-pink coupon strip: "🎟 Up to N% off  ·  🛵 Free delivery" shown when
/// the results carry discounts / free delivery.
class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.shops});
  final List<ShopEntity> shops;

  @override
  Widget build(BuildContext context) {
    var maxOff = 0;
    var anyFree = false;
    for (final s in shops) {
      if (s.freeDelivery) anyFree = true;
      for (final p in s.products) {
        if (p.discountPercent > maxOff) maxOff = p.discountPercent;
      }
    }
    if (maxOff == 0 && !anyFree) return const SizedBox.shrink();
    const brown = AppColors.couponStripBrown;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.couponStripBg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_num_outlined, size: 16, color: brown),
          const SizedBox(width: AppSpacing.s6),
          if (maxOff > 0)
            Flexible(
              child: Text(
                'search.up_to_off'.tr(namedArgs: {'percent': '$maxOff'}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(color: brown),
              ),
            ),
          if (maxOff > 0 && anyFree) ...[
            const SizedBox(width: AppSpacing.s8),
            Container(
              width: 1,
              height: 14,
              color: brown.withValues(alpha: 0.3),
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          if (anyFree) ...[
            const Icon(Icons.delivery_dining_rounded, size: 16, color: brown),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                'search.free_delivery'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(color: brown),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
