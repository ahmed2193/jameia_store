import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../domain/entities/coupon_buckets.dart';
import '../../../domain/entities/coupon_status.dart';
import 'coupons_summary_card.dart';
import 'coupons_tab_bar.dart';
import 'coupons_tab_list.dart';

/// Loaded My coupons: the savings card and the pill tabs drop in, then the
/// three swipeable lists (Available / Used / Expired). The tabs and the lists
/// share one [TabController], so a tap glides the thumb and slides the lists
/// while a swipe drags the thumb along.
class MyCouponsContent extends StatefulWidget {
  const MyCouponsContent({super.key, required this.buckets});

  final CouponBuckets buckets;

  @override
  State<MyCouponsContent> createState() => _MyCouponsContentState();
}

class _MyCouponsContentState extends State<MyCouponsContent>
    with SingleTickerProviderStateMixin {
  static const Offset _dropIn = Offset(0, -0.2);

  /// Built once the motion setting is known: under reduced motion the lists
  /// switch without sliding.
  TabController? _controller;

  TabController get _tabs => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= TabController(
      length: CouponStatus.values.length,
      vsync: this,
      animationDuration: MotionGuard.duration(context, AppMotion.page),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    return ContentClamp(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              0,
            ),
            child: StaggerEntrance(
              index: 0,
              child: CouponsSummaryCard(buckets: buckets),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s20,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: StaggerEntrance(
              index: 2,
              beginOffset: _dropIn,
              child: CouponsTabBar(
                controller: _tabs,
                labels: [
                  'coupons.available'.tr(),
                  'coupons.used'.tr(),
                  'coupons.expired'.tr(),
                ],
                counts: [
                  buckets.available.length,
                  buckets.used.length,
                  buckets.expired.length,
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                CouponsTabList(
                  coupons: buckets.available,
                  status: CouponStatus.available,
                  emptyMessage: 'coupons.none_available'.tr(),
                  emptyIcon: Icons.confirmation_number_outlined,
                ),
                CouponsTabList(
                  coupons: buckets.used,
                  status: CouponStatus.used,
                  emptyMessage: 'coupons.none_used'.tr(),
                  emptyIcon: Icons.task_alt_rounded,
                ),
                CouponsTabList(
                  coupons: buckets.expired,
                  status: CouponStatus.expired,
                  emptyMessage: 'coupons.none_expired'.tr(),
                  emptyIcon: Icons.hourglass_empty_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
