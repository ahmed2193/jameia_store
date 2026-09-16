import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/refund_detail.dart';
import '../cubit/order_refund_detail_cubit.dart';

/// KeeTa refund progress / detail screen (`mach_pro_sailor_c_order_refund_detail`).
///
/// 1:1 clone of the post-request refund status page: a four-stage VERTICAL refund
/// progress tracker (submitted → processing → approved → refunded — mirrors
/// KeeTa's `refund_progress_part_waiting/processing/success/fail` states), a
/// refund-amount breakdown (item refund + delivery refund + voucher/koupon
/// deductions + the wallet-default note), the refund-method row (where the money
/// goes back), and a help / FAQ entry (KeeTa's `jumpToSuccessRate` + customer
/// service jump).
///
/// [KeetaOrder] carries no refund fields, so the refund amount / method are
/// derived from the order total with static demo deductions.
class OrderRefundDetailScreen extends StatelessWidget {
  const OrderRefundDetailScreen({super.key, this.orderId = 'o1'});

  /// Order id resolved from the dummy repository (router passes the tapped id).
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderRefundDetailCubit>()..load(orderId),
      child: const _RefundDetailView(),
    );
  }
}

class _RefundDetailView extends StatelessWidget {
  const _RefundDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(KeetaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'orders.refund_details'.tr(),
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: BlocBuilder<OrderRefundDetailCubit, OrderRefundDetailState>(
        builder: (context, state) {
          return switch (state.status) {
            OrderRefundDetailStatus.initial ||
            OrderRefundDetailStatus.loading => const AppLoader(),
            OrderRefundDetailStatus.error => ErrorView(
              message: 'orders.refund_not_found'.tr(),
              onRetry: () => Navigator.maybePop(context),
            ),
            OrderRefundDetailStatus.loaded => _Loaded(refund: state.refund!),
          };
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.refund});

  final RefundDetail refund;

  @override
  Widget build(BuildContext context) {
    // Stacked refund cards cascade in via the shared StaggerEntrance primitive
    // (reduced-motion → instant), matching the app's list-entrance grammar.
    final cards = <Widget>[
      _RefundHeader(refund: refund),
      _ProgressTracker(stage: refund.stage, eta: refund.etaLabel),
      _AmountBreakdownCard(refund: refund),
      _RefundMethodCard(refund: refund),
      const _HelpCard(),
    ];
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ContentClamp(
            child: Column(
              children: [
                const _CardGap(),
                for (final (i, card) in cards.indexed) ...[
                  StaggerEntrance(index: i, child: card),
                  const _CardGap(),
                ],
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
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.s8);
}

// ── White card shell shared by all sections ───────────────────────────────────

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

// ── Refund header (status headline + shop / order ref) ────────────────────────

class _RefundHeader extends StatelessWidget {
  const _RefundHeader({required this.refund});
  final RefundDetail refund;

  @override
  Widget build(BuildContext context) {
    final done = refund.stage >= _kRefundStages.length;
    return _Card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              done ? KeetaIcons.confirm : KeetaIcons.refund,
              size: 24,
              color: done ? AppColors.success : AppColors.primaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done
                      ? 'orders.refund_completed'.tr()
                      : 'orders.refund_in_progress'.tr(),
                  style: AppTextStyles.displaySmall.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${refund.shopName} · #${refund.orderId.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vertical progress tracker ─────────────────────────────────────────────────

class _RefundStage {
  const _RefundStage(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

// Stage title/subtitle values are translation keys resolved via `.tr()` where
// they are rendered, so the list can stay `const` and stay locale-reactive.
const List<_RefundStage> _kRefundStages = <_RefundStage>[
  _RefundStage(
    'orders.stage_submitted_title',
    'orders.stage_submitted_sub',
    KeetaIcons.orders,
  ),
  _RefundStage(
    'orders.stage_processing_title',
    'orders.stage_processing_sub',
    KeetaIcons.time,
  ),
  _RefundStage(
    'orders.stage_approved_title',
    'orders.stage_approved_sub',
    KeetaIcons.confirm,
  ),
  _RefundStage(
    'orders.stage_refunded_title',
    'orders.stage_refunded_sub',
    KeetaIcons.fastRefund,
  ),
];

class _ProgressTracker extends StatelessWidget {
  const _ProgressTracker({required this.stage, required this.eta});

  /// Number of completed stages, 1..4 (the current active stage = [stage]).
  final int stage;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                KeetaIcons.deliveryTime,
                size: 18,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'orders.refund_progress'.tr(),
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const Spacer(),
              if (stage < _kRefundStages.length)
                Text(
                  eta,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          for (var i = 0; i < _kRefundStages.length; i++)
            _StageRow(
              data: _kRefundStages[i],
              done: (i + 1) <= stage,
              active: (i + 1) == stage,
              isFirst: i == 0,
              isLast: i == _kRefundStages.length - 1,
              // Connector to the NEXT node is lit once that node is reached.
              nextDone: (i + 2) <= stage,
            ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.data,
    required this.done,
    required this.active,
    required this.isFirst,
    required this.isLast,
    required this.nextDone,
  });

  final _RefundStage data;
  final bool done;
  final bool active;
  final bool isFirst;
  final bool isLast;
  final bool nextDone;

  @override
  Widget build(BuildContext context) {
    final nodeColor = done ? AppColors.primary : AppColors.smallBackground;
    final iconColor = done ? AppColors.black : AppColors.tertiaryText;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rail: top connector + node + bottom connector.
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 3,
                  height: AppSpacing.s8,
                  color: isFirst
                      ? AppColors.white
                      : (done ? AppColors.primary : AppColors.divider),
                ),
                // The CURRENT stage node gently pulses (scale + brand halo) to
                // read as "live"; completed/upcoming nodes sit static.
                _PulseNode(
                  active: active,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                      border: active
                          ? Border.all(color: AppColors.primary, width: 3)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(data.icon, size: 15, color: iconColor),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 3,
                    color: isLast
                        ? AppColors.white
                        : (nextDone ? AppColors.primary : AppColors.divider),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          // Labels.
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: done
                          ? AppColors.primaryText
                          : AppColors.tertiaryText,
                      fontWeight: active
                          ? AppTextStyles.bold
                          : AppTextStyles.medium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle.tr(),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.tertiaryText,
                    ),
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

/// Subtle "live" pulse for the CURRENT refund-stage node — a gentle repeating
/// scale + soft brand-yellow halo, mirroring the order-tracking stepper's active
/// node. Inactive (or reduced-motion) → renders the child as-is. All timing/curve
/// comes from [AppMotion] and routes through [MotionGuard].
class _PulseNode extends StatefulWidget {
  const _PulseNode({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_PulseNode> createState() => _PulseNodeState();
}

class _PulseNodeState extends State<_PulseNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseNode old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || MotionGuard.reduced(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.standard);
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) {
        final t = curved.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30 * (1 - t)),
                blurRadius: 4 + 8 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: Transform.scale(scale: 1 + 0.06 * t, child: child),
        );
      },
    );
  }
}

// ── Refund amount breakdown ───────────────────────────────────────────────────

class _AmountBreakdownCard extends StatelessWidget {
  const _AmountBreakdownCard({required this.refund});
  final RefundDetail refund;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                KeetaIcons.refund,
                size: 18,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'orders.refund_amount'.tr(),
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          _AmountLine(
            label: 'orders.item_refund'.tr(),
            value: refund.itemRefund,
          ),
          const SizedBox(height: AppSpacing.s8),
          _AmountLine(
            label: 'orders.delivery_refund'.tr(),
            value: refund.deliveryRefund,
          ),
          const SizedBox(height: AppSpacing.s8),
          _AmountLine(
            label: 'orders.voucher_deduction'.tr(),
            value: -refund.voucherDeduction,
            muted: true,
          ),
          const SizedBox(height: AppSpacing.s12),
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'orders.total_refund'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ),
              Text(
                Formatters.price(refund.totalRefund),
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          const _WalletNote(),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final double value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final sign = value < 0 ? '-' : '';
    final text = '$sign${Formatters.price(value.abs())}';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(
          text,
          style: AppTextStyles.bodyLarge.copyWith(
            color: muted ? AppColors.tertiaryText : AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}

/// KeeTa shows a "refunded to your wallet by default" toast/note on this screen.
class _WalletNote extends StatelessWidget {
  const _WalletNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s10),
      decoration: BoxDecoration(
        color: AppColors.mediumBackground,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(KeetaIcons.info, size: 14, color: AppColors.tertiaryText),
          const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: Text(
              'orders.refund_arrival_note'.tr(),
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Refund method ─────────────────────────────────────────────────────────────

class _RefundMethodCard extends StatelessWidget {
  const _RefundMethodCard({required this.refund});
  final RefundDetail refund;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.smallBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              KeetaIcons.pay,
              size: 20,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'orders.refund_method'.tr(),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  refund.method,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.price(refund.totalRefund),
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Help / FAQ entry ──────────────────────────────────────────────────────────

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _HelpRow(
            icon: KeetaIcons.help,
            label: 'orders.refund_faq'.tr(),
            onTap: () =>
                Navigator.pushNamed(context, Routes.customerServiceQuestion),
          ),
          const ThinDivider(),
          _HelpRow(
            icon: KeetaIcons.customerService,
            label: 'orders.contact_support'.tr(),
            onTap: () => Navigator.pushNamed(context, Routes.customerService),
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
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
            const Icon(
              KeetaIcons.arrowRight,
              size: 16,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}

// The refund stage list length is kept in sync with `RefundDetail.stageCount`.
