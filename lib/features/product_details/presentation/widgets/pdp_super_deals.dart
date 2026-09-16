import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/product_detail.dart';
import '../util/product_detail_display.dart';

/// "Super deals" — a horizontally scrollable rail of first-order / discount
/// coupon cards (KeeMart `SkuCouponComponent`). Each card shows a live
/// "Expires in HH:MM:SS" countdown, a ticket badge, the "{n}% off | {descriptor}"
/// lead and the spend-to-apply threshold.
class SuperDealsRail extends StatelessWidget {
  const SuperDealsRail({super.key, required this.deals});
  final List<DealVM> deals;

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) return const SizedBox.shrink();
    final cardW = (MediaQuery.sizeOf(context).width * 0.82).clamp(280.0, 380.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, AppSpacing.s10),
          child: Text(
            'product.super_deals'.tr(),
            style: AppTextStyles.headingLarge
                .copyWith(fontWeight: AppTextStyles.bold),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16),
            itemCount: deals.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s10),
            itemBuilder: (context, i) =>
                _CouponCard(deal: deals[i], width: cardW.toDouble()),
          ),
        ),
      ],
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.deal, required this.width});
  final DealVM deal;
  final double width;

  @override
  Widget build(BuildContext context) {
    final descriptor = deal.subtitle.isNotEmpty
        ? deal.displaySubtitle
        : 'product.extra_discount_first_order'.tr();
    final bool hasLead = deal.title.isNotEmpty || deal.percent > 0;
    final lead = deal.title.isNotEmpty
        ? deal.displayTitle
        : 'home.percent_off'.tr(namedArgs: {'percent': '${deal.percent}'});

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.s10),
      decoration: BoxDecoration(
        color: kJameiaPromoPink,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CouponCountdown(deadline: deal.deadline),
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: [
              const _TicketBadge(),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (hasLead) ...[
                          Text(
                            lead,
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.primaryText,
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s6),
                          Container(width: 1, height: 12, color: AppColors.divider),
                          const SizedBox(width: AppSpacing.s6),
                        ],
                        Flexible(
                          child: Text(
                            descriptor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.primaryText,
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'product.spend_to_apply'.tr(
                        namedArgs: {'amount': Formatters.price(deal.minSpend)},
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Orange circular ticket/voucher badge.
class _TicketBadge extends StatelessWidget {
  const _TicketBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.accent1,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.confirmation_number_rounded,
        size: 18,
        color: AppColors.white,
      ),
    );
  }
}

/// A once-per-second "Expires in HH:MM:SS" countdown to [deadline]. The single
/// timer is disposed on unmount.
class _CouponCountdown extends StatefulWidget {
  const _CouponCountdown({required this.deadline});
  final DateTime deadline;

  @override
  State<_CouponCountdown> createState() => _CouponCountdownState();
}

class _CouponCountdownState extends State<_CouponCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _compute());
    });
  }

  Duration _compute() {
    final d = widget.deadline.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'product.expires_in'.tr(namedArgs: {'time': _clock}),
      style: AppTextStyles.captionLarge.copyWith(color: AppColors.secondaryText),
    );
  }
}
