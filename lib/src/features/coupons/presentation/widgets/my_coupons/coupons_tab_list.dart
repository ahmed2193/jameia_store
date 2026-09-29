import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/shell_arrival.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/coupon_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../domain/entities/coupon_status.dart';
import '../coupon_card.dart';
import '../coupons_empty_view.dart';

/// One tab of My coupons: its coupons as tickets — the first ones of the tab
/// on screen when the page opens rise in with its cascade from
/// [firstEntranceIndex] (a tab swiped to later, a ticket scrolled back to:
/// as is) — or the friendly empty state. "Use" on an available coupon returns to the shell to go shopping.
class CouponsTabList extends StatelessWidget {
  const CouponsTabList({
    super.key,
    required this.coupons,
    required this.status,
    required this.emptyMessage,
    this.firstEntranceIndex = 0,
  });

  final List<CouponEntity> coupons;
  final CouponStatus status;
  final String emptyMessage;

  /// The first ticket's place in the page's entrance cascade.
  final int firstEntranceIndex;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return CouponsEmptyView(message: emptyMessage);
    }
    return ListView.separated(
      key: PageStorageKey<CouponStatus>(status),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s4,
        AppSpacing.s16,
        AppSpacing.s24 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: coupons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, i) => EntranceCascadeItem(
        index: firstEntranceIndex + i,
        child: CouponCard(
          coupon: coupons[i],
          status: status,
          onUse: status.isAvailable
              ? () => context.go(Routes.shell, extra: ShellArrival())
              : null,
          shimmers: i < CouponCard.maxShimmering,
        ),
      ),
    );
  }
}
