import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

/// KeeTa checkout (`order_confirm_global`) — address bar w/ labels, item list,
/// drop-off options, cutlery toggle, coupon/voucher row, tips, delivery fee,
/// payment-method row (COD / Apple Pay / Google Pay), price breakdown, and a
/// sticky place-order bar. Local UI state (drop-off / cutlery / tip / payment)
/// is held in this page-scoped [State]; values stand in for `v1/order/preview`.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.shopId});
  final String shopId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

/// Drop-off choices mirror KeeTa's `HAND_TO_ME` / `LEAVE_AT_DESIGNATED_SPOT`.
enum _DropOff { handToMe, leaveAtDoor }

/// Payment methods mirror the order_confirm payment-row asset set.
enum _PayMethod { cod, applePay, googlePay }

class _CheckoutScreenState extends State<CheckoutScreen> {
  _DropOff _dropOff = _DropOff.handToMe;
  bool _cutlery = false;
  double _tip = 0;
  _PayMethod _pay = _PayMethod.cod;

  static const _tipOptions = <double>[0, 5, 10, 15];

  @override
  Widget build(BuildContext context) {
    final repo = sl<KeetaRepository>();
    final shop = repo.shopById(widget.shopId);
    final address = repo.defaultAddress;

    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(title: const Text('Checkout')),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return const EmptyStateView(
                message: 'Your cart is empty',
                icon: Icons.shopping_cart_outlined);
          }
          final deliveryFee = shop.freeDelivery ? 0.0 : shop.deliveryFee;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _AddressCard(address: address),
              const SizedBox(height: AppSpacing.s8),
              _ItemsCard(shop: shop, cart: cart),
              const SizedBox(height: AppSpacing.s8),
              _DropOffCard(
                selected: _dropOff,
                onSelect: (d) => setState(() => _dropOff = d),
              ),
              const SizedBox(height: AppSpacing.s8),
              _SwitchRow(
                icon: Icons.restaurant_outlined,
                title: 'Cutlery / tableware',
                subtitle: 'Add disposable cutlery to your order',
                value: _cutlery,
                onChanged: (v) => setState(() => _cutlery = v),
              ),
              const SizedBox(height: AppSpacing.s8),
              _OptionRow(
                  icon: Icons.confirmation_num_outlined,
                  title: 'Coupons & vouchers',
                  trailing: '1 available',
                  trailingColor: AppColors.finalPrice,
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.orderCoupons)),
              _TipRow(
                selected: _tip,
                options: _tipOptions,
                onSelect: (t) => setState(() => _tip = t),
              ),
              const SizedBox(height: AppSpacing.s8),
              _PaymentCard(
                selected: _pay,
                onSelect: (p) => setState(() => _pay = p),
              ),
              const SizedBox(height: AppSpacing.s8),
              _PriceSummary(
                subtotal: cart.subtotal,
                deliveryFee: deliveryFee,
                tip: _tip,
                freeDelivery: shop.freeDelivery,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _PlaceOrderBar(shop: shop, tip: _tip),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});
  final KeetaAddress address;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.finalPrice, size: 22),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Address label chip (Home / Office / Other).
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.r7),
                      ),
                      child: Text(address.label,
                          style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.black,
                              fontWeight: AppTextStyles.bold)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(address.fullText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headingMedium
                              .copyWith(fontWeight: AppTextStyles.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${address.recipient} · ${address.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionLarge
                        .copyWith(color: AppColors.tertiaryText)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.tertiaryText),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.shop, required this.cart});
  final Shop shop;
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KeetaImage.circle(url: shop.logo, size: 24),
              const SizedBox(width: 8),
              Text(shop.name,
                  style: AppTextStyles.headingMedium
                      .copyWith(fontWeight: AppTextStyles.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          for (final line in cart.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  KeetaCardImage(
                      url: line.product.image, width: 44, height: 44, radius: 8),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(line.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge),
                  ),
                  Text('x${line.qty}',
                      style: AppTextStyles.captionLarge
                          .copyWith(color: AppColors.tertiaryText)),
                  const SizedBox(width: AppSpacing.s12),
                  PriceText(price: line.lineTotal, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Drop-off preference (hand-to-me vs leave-at-door), two selectable rows.
class _DropOffCard extends StatelessWidget {
  const _DropOffCard({required this.selected, required this.onSelect});
  final _DropOff selected;
  final ValueChanged<_DropOff> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tile(_DropOff value, IconData icon, String label) {
      final on = value == selected;
      return InkWell(
        onTap: () => onSelect(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.secondaryText),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
              Icon(
                  on
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: on ? AppColors.finalPrice : AppColors.disabledText),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
            child: Text('Delivery preference',
                style: AppTextStyles.captionLarge),
          ),
          tile(_DropOff.handToMe, Icons.pan_tool_alt_outlined, 'Hand it to me'),
          const ThinDivider(indent: AppSpacing.s16),
          tile(_DropOff.leaveAtDoor, Icons.door_front_door_outlined,
              'Leave at the designated spot'),
        ],
      ),
    );
  }
}

/// Toggle row (cutlery / tableware) — KeeTa's tableware switch.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge),
                Text(subtitle,
                    style: AppTextStyles.captionSmall
                        .copyWith(color: AppColors.tertiaryText)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.black,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Rider tips selector — horizontal chips.
class _TipRow extends StatelessWidget {
  const _TipRow(
      {required this.selected, required this.options, required this.onSelect});
  final double selected;
  final List<double> options;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism_outlined,
              size: 20, color: AppColors.secondaryText),
          const SizedBox(width: AppSpacing.s12),
          Text('Rider tip', style: AppTextStyles.bodyLarge),
          const Spacer(),
          for (final t in options)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.s6),
              child: GestureDetector(
                onTap: () => onSelect(t),
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        t == selected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r6),
                    border: Border.all(
                        color: t == selected
                            ? AppColors.primary
                            : AppColors.divider),
                  ),
                  child: Text(t == 0 ? 'None' : Formatters.price(t),
                      style: AppTextStyles.captionLarge.copyWith(
                          fontWeight: t == selected
                              ? AppTextStyles.bold
                              : AppTextStyles.regular)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Payment method picker — COD / Apple Pay / Google Pay.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.selected, required this.onSelect});
  final _PayMethod selected;
  final ValueChanged<_PayMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tile(_PayMethod value, IconData icon, String label) {
      final on = value == selected;
      return InkWell(
        onTap: () => onSelect(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.secondaryText),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
              Icon(
                  on
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: on ? AppColors.finalPrice : AppColors.disabledText),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
            child:
                Text('Payment method', style: AppTextStyles.captionLarge),
          ),
          tile(_PayMethod.cod, Icons.payments_outlined, 'Cash on delivery'),
          const ThinDivider(indent: AppSpacing.s16),
          tile(_PayMethod.applePay, Icons.apple_rounded, 'Apple Pay'),
          const ThinDivider(indent: AppSpacing.s16),
          tile(_PayMethod.googlePay, Icons.account_balance_wallet_outlined,
              'Google Pay'),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.trailingColor,
  });
  final IconData icon;
  final String title;
  final String trailing;
  final VoidCallback onTap;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.secondaryText),
            const SizedBox(width: AppSpacing.s12),
            Text(title, style: AppTextStyles.bodyLarge),
            const Spacer(),
            Text(trailing,
                style: AppTextStyles.captionLarge.copyWith(
                    color: trailingColor ?? AppColors.secondaryText)),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.tertiaryText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.tip,
    required this.freeDelivery,
  });
  final double subtotal;
  final double deliveryFee;
  final double tip;
  final bool freeDelivery;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(label,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.secondaryText)),
              const Spacer(),
              Text(value,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: color ?? AppColors.primaryText)),
            ],
          ),
        );

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          row('Subtotal', Formatters.price(subtotal)),
          row('Delivery fee',
              freeDelivery ? 'Free' : Formatters.price(deliveryFee),
              color: freeDelivery ? AppColors.freeDelivery : null),
          if (tip > 0) row('Rider tip', Formatters.price(tip)),
          const ThinDivider(),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Text('Total',
                    style: AppTextStyles.headingMedium
                        .copyWith(fontWeight: AppTextStyles.bold)),
                const Spacer(),
                PriceText(price: subtotal + deliveryFee + tip, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({required this.shop, required this.tip});
  final Shop shop;
  final double tip;

  void _placeOrder(BuildContext context) {
    final cart = context.read<CartCubit>();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r3)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 56),
            const SizedBox(height: AppSpacing.s12),
            Text('Order placed!',
                style: AppTextStyles.headingLarge
                    .copyWith(fontWeight: AppTextStyles.bold)),
            const SizedBox(height: 4),
            Text('Your order is on the way',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.secondaryText)),
          ],
        ),
        actions: [
          AppButton(
            label: 'Track order',
            onPressed: () {
              cart.clear();
              Navigator.of(context)
                ..pop() // dialog
                ..pop() // checkout
                ..pushNamed(Routes.orderTracking, arguments: 'o1');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        if (cart.isEmpty) return const SizedBox.shrink();
        final deliveryFee = shop.freeDelivery ? 0.0 : shop.deliveryFee;
        final total = cart.subtotal + deliveryFee + tip;
        return SafeArea(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriceText(price: total, size: 20),
                      Text('Incl. fees',
                          style: AppTextStyles.captionSmall
                              .copyWith(color: AppColors.tertiaryText)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: AppButton(
                      label: 'Place order',
                      onPressed: () => _placeOrder(context)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
