import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../domain/entities/coupon_buckets.dart';
import '../../../domain/entities/coupon_status.dart';
import '../coupons_empty_view.dart';
import 'coupons_section_title.dart';
import 'history_coupons_section.dart';

/// Loaded coupon history: the used coupons, then the expired ones, each group
/// under its heading (a group only when it has coupons), or the friendly
/// empty state when there is no history yet.
class HistoryCouponsList extends StatelessWidget {
  const HistoryCouponsList({super.key, required this.buckets});

  final CouponBuckets buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.hasNoHistory) {
      return CouponsEmptyView(
        message: 'coupons.no_history'.tr(),
        icon: Icons.history_rounded,
      );
    }
    final used = buckets.used;
    final expired = buckets.expired;
    return ContentClamp(
      child: CustomScrollView(
        slivers: [
          if (used.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: CouponsSectionTitle(
                text: 'coupons.used'.tr(),
                count: used.length,
              ),
            ),
            HistoryCouponsSection(
              coupons: used,
              status: CouponStatus.used,
              firstIndex: 0,
            ),
          ],
          if (expired.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: CouponsSectionTitle(
                text: 'coupons.expired'.tr(),
                count: expired.length,
              ),
            ),
            HistoryCouponsSection(
              coupons: expired,
              status: CouponStatus.expired,
              firstIndex: used.length,
            ),
          ],
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s24,
            ),
          ),
        ],
      ),
    );
  }
}
