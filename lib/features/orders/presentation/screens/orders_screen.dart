import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';

/// KeeTa Orders list (`mach_pro_sailor_c_order_list`) — two tabs
/// (In progress / History) over [KeetaRepository.orders], per-order shop header,
/// status chip, item summary, date/total, and per-state actions (Track for
/// active orders; Reorder + Review for completed ones). Empty state per tab.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = sl<KeetaRepository>().orders;
    final active = orders.where((o) => o.isActive).toList(growable: false);
    final history = orders.where((o) => !o.isActive).toList(growable: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Orders',
            style: AppTextStyles.displaySmall
                .copyWith(fontWeight: AppTextStyles.bold),
          ),
          bottom: const _OrdersTabBar(),
        ),
        body: TabBarView(
          children: [
            _OrdersList(
              orders: active,
              emptyMessage: 'No orders in progress',
            ),
            _OrdersList(
              orders: history,
              emptyMessage: 'No past orders yet',
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _OrdersTabBar();

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.primaryText,
      indicatorWeight: 3,
      dividerColor: AppColors.divider,
      labelColor: AppColors.primaryText,
      unselectedLabelColor: AppColors.tertiaryText,
      labelStyle:
          AppTextStyles.headingMedium.copyWith(fontWeight: AppTextStyles.bold),
      unselectedLabelStyle: AppTextStyles.headingMedium,
      tabs: const [
        Tab(text: 'In progress'),
        Tab(text: 'History'),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders, required this.emptyMessage});

  final List<KeetaOrder> orders;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyStateView(
        message: emptyMessage,
        icon: KeetaIcons.orders,
      );
    }
    return ContentClamp(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMargin,
          vertical: AppSpacing.s12,
        ),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final KeetaOrder order;

  void _openTracking(BuildContext context) => Navigator.pushNamed(
        context,
        Routes.orderTracking,
        arguments: order.id,
      );

  void _openReview(BuildContext context) => Navigator.pushNamed(
        context,
        Routes.orderReview,
        arguments: order.id,
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => order.isActive
            ? _openTracking(context)
            : Navigator.pushNamed(context, Routes.shop,
                arguments: _shopIdFor(order)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderHeader(order: order),
              const SizedBox(height: AppSpacing.s10),
              const ThinDivider(),
              const SizedBox(height: AppSpacing.s10),
              _OrderItems(items: order.items),
              const SizedBox(height: AppSpacing.s10),
              _OrderFooter(order: order),
              const SizedBox(height: AppSpacing.s12),
              _OrderActions(
                order: order,
                onTrack: () => _openTracking(context),
                onReview: () => _openReview(context),
                onReorder: () => Navigator.pushNamed(context, Routes.shop,
                    arguments: _shopIdFor(order)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolve the order's shop id by name for reorder/shop navigation; falls back
  /// to the first shop when the demo data has no exact match.
  static String _shopIdFor(KeetaOrder order) {
    final shops = sl<KeetaRepository>().shops;
    return shops
        .firstWhere(
          (s) => s.name == order.shopName,
          orElse: () => shops.first,
        )
        .id;
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KeetaImage.circle(url: order.shopLogo, size: 36),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            order.shopName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium
                .copyWith(fontWeight: AppTextStyles.bold),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        _StatusChip(status: order.status),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  ({String label, Color fg, Color bg}) get _style {
    switch (status) {
      case 'delivering':
        return (label: 'Delivering', fg: AppColors.warn, bg: AppColors.warnBg);
      case 'preparing':
        return (label: 'Preparing', fg: AppColors.link, bg: AppColors.blue[0]);
      case 'completed':
        return (
          label: 'Completed',
          fg: AppColors.freeDelivery,
          bg: AppColors.freeDeliveryBg
        );
      case 'cancelled':
        return (label: 'Cancelled', fg: AppColors.error, bg: AppColors.errorBg);
      default:
        return (
          label: status.isEmpty ? 'Unknown' : status,
          fg: AppColors.secondaryText,
          bg: AppColors.smallBackground
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8, vertical: 3),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        s.label,
        style: AppTextStyles.captionLarge
            .copyWith(color: s.fg, fontWeight: AppTextStyles.bold),
      ),
    );
  }
}

class _OrderItems extends StatelessWidget {
  const _OrderItems({required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'x${item.qty}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.tertiaryText),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OrderFooter extends StatelessWidget {
  const _OrderFooter({required this.order});

  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(KeetaIcons.time, size: 13, color: AppColors.tertiaryText),
        const SizedBox(width: AppSpacing.s4),
        Text(
          order.date,
          style: AppTextStyles.captionLarge
              .copyWith(color: AppColors.tertiaryText),
        ),
        const Spacer(),
        Text(
          '${order.itemCount} items · ',
          style: AppTextStyles.captionLarge
              .copyWith(color: AppColors.tertiaryText),
        ),
        Text(
          Formatters.price(order.total),
          style: AppTextStyles.headingSmall
              .copyWith(fontWeight: AppTextStyles.bold),
        ),
      ],
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.onTrack,
    required this.onReview,
    required this.onReorder,
  });

  final KeetaOrder order;
  final VoidCallback onTrack;
  final VoidCallback onReview;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    if (order.isActive) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _PillButton(
          label: 'Track order',
          icon: KeetaIcons.delivery,
          filled: true,
          onPressed: onTrack,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _PillButton(
          label: 'Review',
          icon: KeetaIcons.star,
          onPressed: onReview,
        ),
        const SizedBox(width: AppSpacing.s8),
        _PillButton(
          label: 'Reorder',
          icon: KeetaIcons.orderAgain,
          filled: true,
          onPressed: onReorder,
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.brandForeground : AppColors.primaryText;
    return Material(
      color: filled ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.r1),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r1),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.r1),
                  border: Border.all(color: AppColors.divider),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: AppSpacing.s4),
              Text(
                label,
                style: AppTextStyles.headingSmall
                    .copyWith(color: fg, fontWeight: AppTextStyles.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
