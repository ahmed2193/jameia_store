import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../domain/entities/coupon.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
import '../cubit/coupons_cubit.dart';
import '../widgets/coupon_ticket_card.dart';

/// Jameia **CouponEntity history** page
/// (`mach_pro_sailor_c_market_history_coupon_list`, bundle 25 — "Coupons —
/// history (used/expired/invalid)").
///
/// The history view is the read-only counterpart of [MyCouponsPage]: a single
/// flat feed of the user's spent / lapsed coupons. It reuses the same
/// [CouponsCubit] (which already buckets `JameiaRepository.coupons` into
/// available / used / expired) and renders the `used` + `expired` buckets as
/// greyed [CouponTicketCard]s stamped **Used** / **Expired** (the
/// `market_my_coupon_list` ticket visual, disabled). When neither bucket has
/// any coupon the page shows a centred empty state. The cubit is page-scoped
/// (constructed inline), per the clone's Cubit + get_it convention.
class HistoryCouponsPage extends StatelessWidget {
  const HistoryCouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponsCubit>(),
      child: const _HistoryCouponsView(),
    );
  }
}

class _HistoryCouponsView extends StatelessWidget {
  const _HistoryCouponsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(JameiaIcons.back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'coupons.coupon_history'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: BlocBuilder<CouponsCubit, CouponsState>(
        builder: (context, state) {
          return switch (state.status) {
            CouponsStatus.loaded => _HistoryList(
              used: state.used,
              expired: state.expired,
            ),
            _ => const Skeletonized(loading: true, child: CouponsSkeleton()),
          };
        },
      ),
    );
  }
}

/// One flat list of history tickets: every `used` coupon first (stamped
/// **Used**), then every `expired` coupon (stamped **Expired**). A single
/// pre-built entry list keeps the [ListView.builder] lazy and the row widget
/// trivially `const`-friendly.
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.used, required this.expired});

  final List<CouponEntity> used;
  final List<CouponEntity> expired;

  @override
  Widget build(BuildContext context) {
    if (used.isEmpty && expired.isEmpty) {
      return EmptyStateView(
        message: 'coupons.no_history'.tr(),
        icon: Icons.history_rounded,
      );
    }

    final entries = <_HistoryEntry>[
      for (final c in used) _HistoryEntry(c, CouponStatus.used),
      for (final c in expired) _HistoryEntry(c, CouponStatus.expired),
    ];

    return ContentClamp(
      child: ListView.separated(
        padding: const EdgeInsets.only(
          left: AppSpacing.s12,
          right: AppSpacing.s12,
          top: 3,
        ),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, i) {
          final entry = entries[i];
          // History tickets are read-only — no `onUse` handler, so the card
          // renders the muted Used / Expired stamp instead of the Use button.
          return StaggerEntrance(
            index: i,
            child: CouponTicketCard(coupon: entry.coupon, status: entry.status),
          );
        },
      ),
    );
  }
}

/// Lightweight pairing of a coupon with the history stamp it should render.
class _HistoryEntry {
  const _HistoryEntry(this.coupon, this.status);
  final CouponEntity coupon;
  final CouponStatus status;
}
