import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
// TODO(P2.9-boundary): core Coupon is imported only for the `is Coupon` type
// test on the coupons-picker route result — the picker (another feature) returns
// the core DTO via Navigator, so the core type is kept at this boundary. The
// applied coupon then flows through the cubit/repository as a CouponEntity.
import '../../../../core/data/models/models.dart' show Coupon;
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/entities/keeta_order_entity.dart';
import '../cubit/checkout_cubit.dart';
import '../widgets/checkout/address_bar.dart';
import '../widgets/checkout/coupon_row.dart';
import '../widgets/checkout/drop_off_section.dart';
import '../widgets/checkout/items_section.dart';
import '../widgets/checkout/payment_section.dart';
import '../widgets/checkout/place_order_bar.dart';
import '../widgets/checkout/price_summary.dart';
import '../widgets/checkout/promise_and_tips_section.dart';
import '../widgets/checkout/tableware_row.dart';
import '../widgets/checkout/weather_surge_strip.dart';

/// KeeTa tip chips: 0 / 5 / 10 / 15 SAR (exact labels from bytecode).
const List<double> _tipOptions = <double>[0, 5, 10, 15];

/// KeeTa checkout (`order_confirm_global`) — address bar w/ type icon, item list,
/// drop-off options w/ real bundle assets, cutlery toggle w/ real switch asset,
/// coupon/voucher row, on-time promise, tips w/ KeeTa chip style, payment method
/// picker w/ real pay logos, price breakdown, and a sticky full-width yellow CTA.
///
/// The business state (coupon, drop-off, cutlery, tip, payment) lives in
/// [CheckoutCubit] as a [CheckoutDraft]; the shared app-root [CartCubit] still
/// supplies the cart lines/subtotal. The two cubits stay decoupled — the screen
/// bridges the cart snapshot into `placeOrder` and clears the cart once placed.
///
/// Real metrics from bundle.css.json:
///   page-bg   = #F0F1F5 (smallBackground)
///   card-bg   = #FFFFFF edge-to-edge (no card radius)
///   gap       = 8dp between sections
///   section-title = 16dp/w500/#222222 padding:0dp 16dp mb:12dp
///   option-row  = padding-v 14dp, icon 20dp
///   tip-chip    = h:30dp r:10dp, selected #FFE41F, unselected #EBEBEB
///   place-order = h:50dp r:25dp (pill) full-width #FFE41F
///   bottom-bar  = padding 16dp 16dp 34dp 16dp (leaves safe area)
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CheckoutCubit>()..start(shopId),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  AppBar _appBar() => AppBar(
    title: Text('checkout.title'.tr()),
    backgroundColor: AppColors.white,
    elevation: 0,
    shadowColor: AppColors.divider,
  );

  /// Open the coupons picker and apply a picked coupon; a null result (system
  /// back / "Don't use a coupon") leaves the current selection untouched.
  Future<void> _openCoupons(BuildContext context) async {
    final picked = await Navigator.pushNamed(context, Routes.orderCoupons);
    if (!context.mounted) return;
    // The picker returns a core Coupon (boundary); the cubit re-validates by id
    // and stores the applied CouponEntity.
    if (picked is Coupon) {
      context.read<CheckoutCubit>().applyCoupon(picked.id);
    }
  }

  /// Once the order is committed: empty the shared cart (the screen bridges the
  /// decoupled [CartCubit]) and show the success dialog that deep-links to the
  /// real order's tracking screen.
  void _onPlaced(BuildContext context, CheckoutState state) {
    final order = state.placedOrder;
    if (order == null) return;
    context.read<CartCubit>().clear();
    _showSuccess(context, order);
  }

  /// A place-order commit failed (see the listener): tell the user instead of
  /// silently doing nothing, so they can retry the CTA.
  void _onPlaceFailed(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('checkout.place_failed'.tr())));
  }

  void _showSuccess(BuildContext context, KeetaOrderEntity order) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(KeetaIcons.confirm, color: AppColors.success, size: 56),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'checkout.order_placed'.tr(),
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'checkout.order_on_way'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'checkout.track_order'.tr(),
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..pop()
                ..pushNamed(Routes.orderTracking, arguments: order.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (p, c) =>
          (c.status == CheckoutStatus.placed &&
              p.status != CheckoutStatus.placed) ||
          // A failed commit (placing → error) must not be a silent no-op.
          (c.status == CheckoutStatus.error &&
              p.status == CheckoutStatus.placing),
      listener: (context, cs) {
        if (cs.status == CheckoutStatus.placed) {
          _onPlaced(context, cs);
        } else {
          _onPlaceFailed(context);
        }
      },
      // Draft edits (tip/coupon/drop-off/cutlery/payment) must NOT rebuild the
      // whole page: the skeleton reacts only to context/status changes; each
      // draft-driven row self-scopes via a BlocSelector below.
      buildWhen: (p, c) =>
          p.shop != c.shop ||
          p.address != c.address ||
          p.status != c.status ||
          p.availableCouponCount != c.availableCouponCount,
      builder: (context, cs) {
        final shop = cs.shop;
        final address = cs.address;
        // Loading the in-memory context resolves in one microtask; show the
        // page shell with a branded loader until shop + address land.
        if (shop == null || address == null) {
          // A context-load failure (start()) lands here with status == error;
          // show a retry instead of an infinite loader.
          final body = cs.status == CheckoutStatus.error
              ? ErrorView(onRetry: () => context.read<CheckoutCubit>().retry())
              : const AppLoader();
          return Scaffold(
            backgroundColor: AppColors.smallBackground,
            appBar: _appBar(),
            body: body,
          );
        }

        return Scaffold(
          // Real KeeTa page bg = #F0F1F5 (system-color-neutral-smallBackground).
          backgroundColor: AppColors.smallBackground,
          appBar: _appBar(),
          body: BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) {
              if (cart.isEmpty) {
                return EmptyStateView(
                  message: 'checkout.cart_empty'.tr(),
                  icon: KeetaIcons.cart,
                );
              }
              final cubit = context.read<CheckoutCubit>();
              final deliveryFee = shop.effectiveDeliveryFee;
              return ListView(
                // bottom padding = 120dp to clear the sticky bar height
                padding: const EdgeInsetsDirectional.only(bottom: 120),
                children: [
                  // ── 1. Address bar ───────────────────────────────────────
                  AddressBar(address: address),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 2. Order items (rebuilds on cart only, never on draft) ─
                  ItemsSection(shop: shop, cart: cart),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 3. Drop-off preference (scoped to draft.dropOff) ─────
                  BlocSelector<CheckoutCubit, CheckoutState, DropOffOption>(
                    selector: (s) => s.draft.dropOff,
                    builder: (_, dropOff) => DropOffSection(
                      selected: dropOff,
                      onSelect: cubit.setDropOff,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 4. Cutlery / tableware switch (scoped to draft.cutlery)
                  BlocSelector<CheckoutCubit, CheckoutState, bool>(
                    selector: (s) => s.draft.cutlery,
                    builder: (_, cutlery) => TablewareRow(
                      value: cutlery,
                      onChanged: cubit.setCutlery,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 5. Coupons & vouchers (draft.coupon + cart.subtotal) ─
                  BlocSelector<CheckoutCubit, CheckoutState, CouponEntity?>(
                    selector: (s) => s.draft.coupon,
                    builder: (_, coupon) => CouponRow(
                      onTap: () => _openCoupons(context),
                      selected: coupon,
                      discount: CheckoutDraft(
                        coupon: coupon,
                      ).discountFor(cart.subtotal),
                      availableCount: cs.availableCouponCount,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 6. On-time promise + rider tips (scoped to draft.tip) ─
                  BlocSelector<CheckoutCubit, CheckoutState, double>(
                    selector: (s) => s.draft.tip,
                    builder: (_, tip) => PromiseAndTipsSection(
                      tip: tip,
                      options: _tipOptions,
                      onTipSelect: cubit.setTip,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 7. Payment method (scoped to draft.payMethod) ────────
                  BlocSelector<CheckoutCubit, CheckoutState, PaymentMethod>(
                    selector: (s) => s.draft.payMethod,
                    builder: (_, method) => PaymentSection(
                      selected: method,
                      onSelect: cubit.setPayment,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 8. Weather surge strip ───────────────────────────────
                  const WeatherSurgeStrip(),
                  const SizedBox(height: AppSpacing.s8),

                  // ── 9. Price summary (cart.subtotal + draft.tip/coupon) ──
                  BlocSelector<
                    CheckoutCubit,
                    CheckoutState,
                    ({double tip, CouponEntity? coupon})
                  >(
                    selector: (s) => (tip: s.draft.tip, coupon: s.draft.coupon),
                    builder: (_, sel) => PriceSummary(
                      subtotal: cart.subtotal,
                      deliveryFee: deliveryFee,
                      tip: sel.tip,
                      discount: CheckoutDraft(
                        coupon: sel.coupon,
                      ).discountFor(cart.subtotal),
                      coupon: sel.coupon,
                      freeDelivery: shop.freeDelivery,
                    ),
                  ),
                ],
              );
            },
          ),
          // Sticky CTA re-totals only when tip/coupon change (or cart, via its
          // own inner BlocBuilder<CartCubit>).
          bottomNavigationBar:
              BlocSelector<
                CheckoutCubit,
                CheckoutState,
                ({double tip, CouponEntity? coupon})
              >(
                selector: (s) => (tip: s.draft.tip, coupon: s.draft.coupon),
                builder: (context, _) => PlaceOrderBar(
                  shop: shop,
                  draft: context.read<CheckoutCubit>().state.draft,
                ),
              ),
        );
      },
    );
  }
}
