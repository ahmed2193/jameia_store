import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/order_tracking_cubit.dart';

/// KeeTa order tracking / order-detail screen (`mach_pro_sailor_c_order_status_global`).
///
/// 1:1 clone of the live-tracking page: styled live-map placeholder (real KeeTa
/// rider/shop/user markers), confirm→prepare→pickup→on-the-way→delivered progress
/// stepper bound to [KeetaOrder.statusStep], ETA bubble, rider action bar
/// (call + chat), order summary (items / total / payment), delivery address from
/// [KeetaRepository.defaultAddress], and a help / refund entry.
///
/// [KeetaOrder] has no payment/address fields, so the payment row uses a static
/// label and the address row reads the default address.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, this.orderId = 'o1'});

  /// Order id resolved from the dummy repository (router passes the tapped id).
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderTrackingCubit(sl<KeetaRepository>())..load(orderId),
      child: const _OrderTrackingView(),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  const _OrderTrackingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
        builder: (context, state) {
          return switch (state) {
            OrderTrackingLoading() => const AppLoader(),
            OrderTrackingError() => ErrorView(
                message: 'Order not found',
                onRetry: () => Navigator.maybePop(context),
              ),
            OrderTrackingLoaded(:final order, :final address) =>
              _Loaded(order: order, address: address),
          };
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.order, required this.address});

  final KeetaOrder order;
  final KeetaAddress address;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Live-map placeholder with rider/shop/user markers + floating back button.
        SliverToBoxAdapter(child: _MapHero(order: order)),
        SliverToBoxAdapter(
          child: ContentClamp(
            child: Column(
              children: [
                _StatusHeader(order: order),
                const _CardGap(),
                _ProgressStepper(step: order.statusStep),
                if (order.rider != null) ...[
                  const _CardGap(),
                  _RiderBar(rider: order.rider!),
                ],
                const _CardGap(),
                _OrderSummaryCard(order: order),
                const _CardGap(),
                _DeliveryAddressCard(address: address),
                const _CardGap(),
                const _HelpRefundCard(),
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Consistent vertical gap between the stacked white cards.
class _CardGap extends StatelessWidget {
  const _CardGap();
  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: AppSpacing.s8);
}

// ── Status step labels (statusStep 1..5) ──────────────────────────────────────

const List<String> _kStepLabels = <String>[
  'Confirmed',
  'Preparing',
  'Picked up',
  'On the way',
  'Delivered',
];

const List<String> _kStepNodes = <String>[
  KeetaAssets.progressNodeConfirm,
  KeetaAssets.progressNodePrepare,
  KeetaAssets.progressNodeMotor,
  KeetaAssets.progressNodeCar,
  KeetaAssets.progressNodeDelivery,
];

String _statusHeadline(int step) {
  return switch (step) {
    1 => 'Order confirmed',
    2 => 'Preparing your order',
    3 => 'Rider picked up your order',
    4 => 'On the way to you',
    _ => 'Delivered — enjoy!',
  };
}

// ── Live-map placeholder ──────────────────────────────────────────────────────

class _MapHero extends StatelessWidget {
  const _MapHero({required this.order});
  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final isCar = order.rider?.vehicle == 'car';
    final riderMarker =
        isCar ? KeetaAssets.riderMarkerCar : KeetaAssets.riderMarkerMotorbike;

    return SizedBox(
      height: 320 + topPad,
      child: Stack(
        children: [
          // Stylized map backdrop (no real map SDK — gradient + grid feel).
          const Positioned.fill(child: _MapBackdrop()),
          // Shop pin (top-start).
          PositionedDirectional(
            top: topPad + 70,
            start: 48,
            child: _MapMarker(asset: KeetaAssets.shopMarker, size: 40),
          ),
          // Rider marker (center) — the moving courier.
          Align(
            alignment: const Alignment(0, -0.05),
            child: RepaintBoundary(
              child: _MapMarker(asset: riderMarker, size: 56),
            ),
          ),
          // User / destination pin (bottom-end).
          PositionedDirectional(
            bottom: 96,
            end: 56,
            child: _MapMarker(asset: KeetaAssets.userMarker, size: 40),
          ),
          // Floating circular back button.
          PositionedDirectional(
            top: topPad + AppSpacing.s8,
            start: AppSpacing.s12,
            child: const _CircleBack(),
          ),
          // ETA bubble pinned to the bottom of the map.
          PositionedDirectional(
            start: AppSpacing.pageMargin,
            end: AppSpacing.pageMargin,
            bottom: AppSpacing.s12,
            child: _EtaBubble(order: order),
          ),
        ],
      ),
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.smallBackground, AppColors.mediumBackground],
        ),
      ),
      child: CustomPaint(
        painter: _RoutePainter(),
        size: Size.infinite,
      ),
    );
  }
}

/// Dashed delivery route line connecting shop → rider → destination.
class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.10,
        size.width * 0.52, size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.54, size.height * 0.80,
        size.width * 0.82, size.height * 0.70,
      );

    // Dashed stroke.
    final metric = path.computeMetrics().first;
    const dash = 14.0;
    const gap = 9.0;
    double dist = 0;
    while (dist < metric.length) {
      final next = (dist + dash).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(dist, next), paint);
      dist = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.asset, required this.size});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            KeetaIcons.location,
            size: size,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack();
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
              color: AppColors.overlayDivider,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s8),
          child: Icon(KeetaIcons.back, size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}

class _EtaBubble extends StatelessWidget {
  const _EtaBubble({required this.order});
  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    final delivered = order.statusStep >= 5;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(KeetaIcons.deliveryTime,
                size: 22, color: AppColors.black),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivered ? 'Delivered' : 'Estimated arrival',
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  delivered ? 'Order completed' : '15 – 25 min',
                  style: AppTextStyles.headingMedium
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
              ],
            ),
          ),
          Image.asset(
            KeetaAssets.onTimePromiseLogo,
            height: 22,
            errorBuilder: (_, _, _) => const Icon(KeetaIcons.confirm,
                size: 20, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

// ── White card shell shared by all detail sections ────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: child,
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});
  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          KeetaImage.circle(url: order.shopLogo, size: 40),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusHeadline(order.statusStep),
                  style: AppTextStyles.displaySmall
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.shopName} · #${order.id.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress stepper ──────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({required this.step});

  /// Current order step, 1..5.
  final int step;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _kStepLabels.length; i++)
            Expanded(
              child: _StepNode(
                label: _kStepLabels[i],
                node: _kStepNodes[i],
                done: (i + 1) <= step,
                active: (i + 1) == step,
                // Left connector lit when THIS node is reached; right connector
                // lit when the NEXT node is also reached.
                leftDone: (i + 1) <= step && i > 0,
                rightDone: (i + 2) <= step,
                isFirst: i == 0,
                isLast: i == _kStepLabels.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.node,
    required this.done,
    required this.active,
    required this.leftDone,
    required this.rightDone,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final String node;
  final bool done;
  final bool active;
  final bool leftDone;
  final bool rightDone;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const lineDone = AppColors.primary;
    const lineTodo = AppColors.divider;
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Connector lines (outer halves are blank on the end nodes).
              PositionedDirectional(
                start: 0,
                end: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isFirst
                            ? AppColors.white
                            : (leftDone ? lineDone : lineTodo),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isLast
                            ? AppColors.white
                            : (rightDone ? lineDone : lineTodo),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: MotionGuard.duration(context, AppMotion.medium),
                curve: AppMotion.standard,
                width: active ? 30 : 26,
                height: active ? 30 : 26,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : AppColors.smallBackground,
                  shape: BoxShape.circle,
                  border: active
                      ? Border.all(color: AppColors.primary, width: 3)
                      : null,
                ),
                alignment: Alignment.center,
                child: done
                    ? Image.asset(
                        node,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          KeetaIcons.confirm,
                          size: 14,
                          color: AppColors.black,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionSmall.copyWith(
            color: done ? AppColors.primaryText : AppColors.tertiaryText,
            fontWeight: active ? AppTextStyles.bold : AppTextStyles.regular,
          ),
        ),
      ],
    );
  }
}

// ── Rider action bar ──────────────────────────────────────────────────────────

class _RiderBar extends StatelessWidget {
  const _RiderBar({required this.rider});
  final Rider rider;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.smallBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(KeetaIcons.delivery,
                size: 22, color: AppColors.secondaryText),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: AppTextStyles.headingSmall
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your rider · ${rider.vehicle}',
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText),
                ),
              ],
            ),
          ),
          _RiderAction(icon: KeetaIcons.chat, onTap: () {}),
          const SizedBox(width: AppSpacing.s8),
          _RiderAction(icon: KeetaIcons.phone, onTap: () {}),
        ],
      ),
    );
  }
}

class _RiderAction extends StatelessWidget {
  const _RiderAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.black),
      ),
    );
  }
}

// ── Order summary ─────────────────────────────────────────────────────────────

/// [KeetaOrder] carries no payment field — show a fixed demo payment label.
const String _kPaymentLabel = 'Apple Pay';

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});
  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(KeetaIcons.orders,
                  size: 18, color: AppColors.primaryText),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Order summary',
                style: AppTextStyles.headingSmall
                    .copyWith(fontWeight: AppTextStyles.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          // Items list — short and fixed-length, safe in a Column.
          for (final item in order.items) ...[
            _SummaryItemRow(item: item),
            const SizedBox(height: AppSpacing.s8),
          ],
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s12),
          _SummaryLine(
            label: 'Total',
            value: Formatters.price(order.total),
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.s8),
          _SummaryLine(label: 'Payment', value: _kPaymentLabel),
          const SizedBox(height: AppSpacing.s8),
          _SummaryLine(label: 'Order date', value: order.date),
        ],
      ),
    );
  }
}

class _SummaryItemRow extends StatelessWidget {
  const _SummaryItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.qty}×',
          style: AppTextStyles.bodyLarge
              .copyWith(color: AppColors.tertiaryText),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(item.name, style: AppTextStyles.bodyLarge),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          Formatters.price(item.price * item.qty),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueStyle = emphasize
        ? AppTextStyles.headingMedium.copyWith(fontWeight: AppTextStyles.bold)
        : AppTextStyles.bodyLarge;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.secondaryText),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ── Delivery address ──────────────────────────────────────────────────────────

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({required this.address});
  final KeetaAddress address;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(KeetaIcons.location,
              size: 20, color: AppColors.primaryText),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to ${address.label}',
                  style: AppTextStyles.headingSmall
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  address.fullText,
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  '${address.recipient} · ${address.phone}',
                  style: AppTextStyles.captionSmall
                      .copyWith(color: AppColors.tertiaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Help / refund entry ───────────────────────────────────────────────────────

class _HelpRefundCard extends StatelessWidget {
  const _HelpRefundCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _HelpRow(
            icon: KeetaIcons.customerService,
            label: 'Get help with this order',
            onTap: () =>
                Navigator.pushNamed(context, Routes.customerService),
          ),
          const ThinDivider(),
          _HelpRow(
            icon: KeetaIcons.refund,
            label: 'Request a refund',
            onTap: () => Navigator.pushNamed(context, Routes.orderRefund),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryText),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLarge),
            ),
            const Icon(KeetaIcons.arrowRight,
                size: 16, color: AppColors.tertiaryText),
          ],
        ),
      ),
    );
  }
}
