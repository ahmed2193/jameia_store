import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../shop/presentation/pages/shop_page.dart' show shopRouteArg;
import '../../../store_mode/domain/repositories/store_mode_repository.dart';
import '../../../store_mode/presentation/cubit/store_mode_cubit.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/product_details_repository.dart';
import '../cubit/product_detail_cubit.dart';
import '../widgets/pdp_bottom_bar.dart';
import '../widgets/pdp_gallery.dart';
import '../widgets/pdp_product_card.dart';
import '../widgets/pdp_recipes.dart';
import '../widgets/pdp_super_deals.dart';

/// Full-screen KeeMart product-detail page (PDP). Pushed via
/// [Routes.productDetail] (a slide-up transition page) so it slides up from the
/// bottom with an X close.
///
/// Sections, top → bottom: collapsing app bar over the image/nutrition gallery →
/// title → delivery ETA → Super deals → Product details → brand row → (variant
/// options) → Similar Products → Recommended Recipes → Explore More →
/// satisfaction feedback → footer; with a sticky Add-to-cart bar. All section
/// data is the seeded [ProductDetail] loaded via [ProductDetailsRepository].
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(
        product: product,
        repository: sl<ProductDetailsRepository>(),
        storeMode: sl<StoreModeRepository>(),
      ),
      // The store mode (VIP ⇄ Mart) is a plain value source; re-derive pricing
      // when the root StoreModeCubit flips it.
      child: BlocListener<StoreModeCubit, StoreModeState>(
        listenWhen: (a, b) => a.isVip != b.isVip,
        listener: (context, _) =>
            context.read<ProductDetailCubit>().onVipModeChanged(),
        child: const _ProductDetailView(),
      ),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView();

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  // While the PDP covers the shell tab bar, fly-to-cart must land on THIS app
  // bar's cart icon, not the occluded shell one.
  final GlobalKey _cartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    FlyToCart.pushTarget(_cartKey);
  }

  @override
  void dispose() {
    FlyToCart.popTarget(_cartKey);
    super.dispose();
  }

  void _openProduct(Product p) {
    context.push(Routes.productDetail, extra: p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      bottomNavigationBar: const PdpBottomBar(),
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        buildWhen: (a, b) => a.status != b.status,
        builder: (context, state) {
          switch (state.status) {
            case ProductDetailStatus.initial:
            case ProductDetailStatus.loading:
              return const Center(child: AppLoader());
            case ProductDetailStatus.error:
              return ErrorView(
                onRetry: () => context.read<ProductDetailCubit>().load(),
              );
            case ProductDetailStatus.loaded:
              return _Loaded(
                detail: context.read<ProductDetailCubit>().detail,
                cartKey: _cartKey,
                onOpenProduct: _openProduct,
              );
          }
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.detail,
    required this.cartKey,
    required this.onOpenProduct,
  });

  final ProductDetail detail;
  final GlobalKey cartKey;
  final void Function(Product) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final hero = detail.product;

    return CustomScrollView(
      slivers: [
        _PdpAppBar(title: hero.displayName, cartKey: cartKey),

        // Title.
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: Text(
              hero.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ),

        // Delivery ETA.
        if (detail.prepMinutes > 0)
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s12,
              ),
              child: _EtaRow(minutes: detail.prepMinutes),
            ),
          ),

        // Super deals.
        SliverToBoxAdapter(
          child: ColoredBox(
            color: AppColors.white,
            child: SuperDealsRail(deals: detail.deals),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),

        // Product details.
        SliverToBoxAdapter(child: _SpecCard(detail: detail)),

        // Brand row.
        if (detail.brand.name.isNotEmpty)
          SliverToBoxAdapter(child: _BrandRow(brand: detail.brand)),

        // Variant options.
        if (hero.hasVariants)
          SliverToBoxAdapter(child: _VariantSection(product: hero)),

        // Similar Products.
        SliverToBoxAdapter(
          child: _ProductGrid(
            title: 'product.similar_products'.tr(),
            products: detail.similar,
            onOpenProduct: onOpenProduct,
          ),
        ),

        // Recommended Recipes.
        SliverToBoxAdapter(
          child: ColoredBox(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: RecipesRail(recipes: detail.recipes),
            ),
          ),
        ),

        // Explore More.
        SliverToBoxAdapter(
          child: _ProductGrid(
            title: 'product.explore_more'.tr(),
            products: detail.exploreMore,
            onOpenProduct: onOpenProduct,
          ),
        ),

        // Satisfaction feedback.
        const SliverToBoxAdapter(child: _SatisfactionCard()),

        // Footer.
        const SliverToBoxAdapter(child: _PdpFooter()),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s16)),
      ],
    );
  }
}

// ── Collapsing app bar over the gallery ───────────────────────────────────────
class _PdpAppBar extends StatelessWidget {
  const _PdpAppBar({required this.title, required this.cartKey});
  final String title;
  final GlobalKey cartKey;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final expanded = size.width.clamp(320.0, 460.0);

    return SliverAppBar(
      pinned: true,
      expandedHeight: expanded,
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      foregroundColor: AppColors.primaryText,
      elevation: 0,
      leading: _TopAction(
        icon: JameiaIcons.close,
        onTap: () => Navigator.maybePop(context),
      ),
      actions: [
        _TopAction(icon: JameiaIcons.share, onTap: () {}),
        _TopAction(icon: JameiaIcons.search, onTap: () {}),
        _CartAction(cartKey: cartKey),
        const SizedBox(width: AppSpacing.s8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsed =
              constraints.maxHeight <= kToolbarHeight + topPad + 8;
          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsetsDirectional.only(
              start: 56,
              end: 16,
              bottom: 15,
            ),
            title: AnimatedOpacity(
              opacity: collapsed ? 1 : 0,
              duration: MotionGuard.duration(context, AppMotion.fast),
              // Constrain so the title ellipsizes BEFORE the share/search/cart
              // actions instead of running under them.
              child: SizedBox(
                width: (size.width - 56 - 150).clamp(80.0, size.width),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ),
            background: const PdpGallery(),
          );
        },
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: AppColors.primaryText),
      splashRadius: 22,
    );
  }
}

/// App-bar cart icon carrying the fly-to-cart target key and a red count badge.
class _CartAction extends StatelessWidget {
  const _CartAction({required this.cartKey});
  final GlobalKey cartKey;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, int>(
      selector: (s) => s.totalQty,
      builder: (context, qty) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => context.push(Routes.cartPreview),
              icon: Icon(
                JameiaIcons.cart,
                key: cartKey,
                size: 22,
                color: AppColors.primaryText,
              ),
              splashRadius: 22,
            ),
            if (qty > 0)
              PositionedDirectional(
                end: 4,
                top: 4,
                child: PopScale(
                  popKey: qty,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.finalPrice,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Delivery ETA row ──────────────────────────────────────────────────────────
class _EtaRow extends StatelessWidget {
  const _EtaRow({required this.minutes});
  final int minutes;

  String get _arrival {
    final t = DateTime.now().add(Duration(minutes: minutes));
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.martGreen,
            borderRadius: BorderRadius.circular(AppRadius.r6),
          ),
          child: const Icon(Icons.bolt, size: 15, color: AppColors.white),
        ),
        const SizedBox(width: AppSpacing.s6),
        Text(
          'product.eta_mins'.tr(namedArgs: {'mins': '$minutes'}),
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.primaryText,
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.s6),
        Flexible(
          child: Text(
            '·  ${'product.est_arrival'.tr(namedArgs: {'time': _arrival})}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Product details (spec) card ───────────────────────────────────────────────
class _SpecCard extends StatelessWidget {
  const _SpecCard({required this.detail});
  final ProductDetail detail;

  @override
  Widget build(BuildContext context) {
    final hero = detail.product;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(label: 'product.product_details'.tr()),
          const SizedBox(height: AppSpacing.s10),
          if (hero.desc.isNotEmpty) ...[
            Text(
              hero.desc,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          if (detail.storage.isNotEmpty)
            _SpecRow(label: 'product.storage'.tr(), value: detail.storage.tr()),
          if (detail.weight.isNotEmpty)
            _SpecRow(label: 'product.weight'.tr(), value: detail.weight),
          if (detail.kcal > 0)
            _SpecRow(
              label: 'product.calories'.tr(),
              value: 'product.kcal'.tr(namedArgs: {'kcal': '${detail.kcal}'}),
            ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Brand row ─────────────────────────────────────────────────────────────────
class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.brand});
  final BrandInfo brand;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: InkWell(
        onTap: brand.categoryId.isEmpty
            ? null
            : () => context.push(
                Routes.shop,
                extra: shopRouteArg(brand.categoryId),
              ),
        child: Row(
          children: [
            JameiaImage(
              url: brand.logo,
              width: 40,
              height: 40,
              radius: AppRadius.r6,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'product.explore_all_products'.tr(),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              JameiaIcons.arrowRight,
              size: 16,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Variant (options) selector ────────────────────────────────────────────────
class _VariantSection extends StatelessWidget {
  const _VariantSection({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(label: 'shop.options'.tr()),
          const SizedBox(height: AppSpacing.s10),
          BlocBuilder<ProductDetailCubit, ProductDetailState>(
            buildWhen: (a, b) => a.variantIndex != b.variantIndex,
            builder: (context, state) {
              return Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (var i = 0; i < product.variants.length; i++)
                    _VariantChip(
                      variant: product.variants[i],
                      selected: i == state.variantIndex,
                      onTap: product.variants[i].inStock
                          ? () => context
                                .read<ProductDetailCubit>()
                                .selectVariant(i)
                          : null,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.variant,
    required this.selected,
    required this.onTap,
  });
  final ProductVariant variant;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final Color bg;
    final Color fg;
    final Color border;
    if (selected) {
      bg = AppColors.martGreenLight;
      fg = AppColors.martGreen;
      border = AppColors.martGreen;
    } else if (disabled) {
      bg = AppColors.smallBackground;
      fg = AppColors.disabledText;
      border = AppColors.divider;
    } else {
      bg = AppColors.white;
      fg = AppColors.primaryText;
      border = AppColors.divider;
    }
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: variant.label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44),
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.r6),
            border: Border.all(color: border, width: 1),
          ),
          child: Text(
            variant.label,
            style: AppTextStyles.captionLarge.copyWith(
              color: fg,
              fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
              decoration: disabled ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Product grid (Similar / Explore) ──────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.title,
    required this.products,
    required this.onOpenProduct,
  });
  final String title;
  final List<Product> products;
  final void Function(Product) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final cardW =
        (MediaQuery.sizeOf(context).width -
            AppSpacing.s16 * 2 -
            AppSpacing.s12) /
        2;

    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s10,
            ),
            child: Text(
              title,
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          BlocBuilder<StoreModeCubit, StoreModeState>(
            builder: (context, mode) {
              final vip = mode.isVip;
              return Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s16,
                ),
                child: Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s16,
                  children: [
                    for (var i = 0; i < products.length; i++)
                      StaggerEntrance(
                        index: i,
                        child: PdpProductCard(
                          product: products[i],
                          vip: vip,
                          width: cardW,
                          onTap: () => onOpenProduct(products[i]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Satisfaction feedback ─────────────────────────────────────────────────────
class _SatisfactionCard extends StatelessWidget {
  const _SatisfactionCard();

  void _pick(BuildContext context, Satisfaction value) {
    context.read<ProductDetailCubit>().setSatisfaction(value);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('product.thanks_feedback'.tr()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'product.satisfaction_question'.tr(),
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          BlocBuilder<ProductDetailCubit, ProductDetailState>(
            buildWhen: (a, b) => a.satisfaction != b.satisfaction,
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: _FeedbackPill(
                      emoji: '😠',
                      label: 'product.not_satisfied'.tr(),
                      selected: state.satisfaction == Satisfaction.notSatisfied,
                      onTap: () => _pick(context, Satisfaction.notSatisfied),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: _FeedbackPill(
                      emoji: '😄',
                      label: 'product.satisfied'.tr(),
                      selected: state.satisfaction == Satisfaction.satisfied,
                      onTap: () => _pick(context, Satisfaction.satisfied),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeedbackPill extends StatelessWidget {
  const _FeedbackPill({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.martGreenLight : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r1),
          border: Border.all(
            color: selected ? AppColors.martGreen : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: AppSize.font16)),
            const SizedBox(width: AppSpacing.s6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: selected ? AppColors.martGreen : AppColors.primaryText,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _PdpFooter extends StatelessWidget {
  const _PdpFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mediumBackground,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
      child: Column(
        children: [
          Text(
            'product.brand_watermark'.tr(),
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.divider,
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FooterProp(
                    icon: Icons.bolt,
                    label: 'product.footer_fast_delivery'.tr(),
                  ),
                  _FooterDot(),
                  _FooterProp(
                    icon: Icons.inventory_2_outlined,
                    label: 'product.footer_various_products'.tr(),
                  ),
                  _FooterDot(),
                  _FooterProp(
                    icon: Icons.sell_outlined,
                    label: 'product.footer_fair_price'.tr(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: Icon(Icons.circle, size: 3, color: AppColors.disabledText),
    );
  }
}

class _FooterProp extends StatelessWidget {
  const _FooterProp({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.disabledText),
        const SizedBox(width: AppSpacing.s4),
        Text(
          label,
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ],
    );
  }
}

// ── Shared card / sub-header (mirrors shop_detail_screen) ──────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.headingMedium.copyWith(
        fontWeight: AppTextStyles.bold,
      ),
    );
  }
}
