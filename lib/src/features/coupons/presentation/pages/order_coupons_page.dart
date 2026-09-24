import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../domain/entities/coupon.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
import '../cubit/coupons_cubit.dart';

/// Jameia order-checkout coupon picker (`mach_pro_sailor_c_market_order_coupon_list`).
///
/// A radio-select list of available coupon tickets plus a "Don't use a coupon"
/// option, with a sticky [AppButton] that pops the chosen [CouponEntity] (or `null`)
/// back to the checkout screen. Page-scoped [CouponsCubit] is built inline.
class OrderCouponsPage extends StatelessWidget {
  const OrderCouponsPage({super.key, this.selectedId});

  /// Id of the coupon already applied to the order (pre-selects its radio).
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponsCubit>(),
      child: _OrderCouponsView(selectedId: selectedId),
    );
  }
}

class _OrderCouponsView extends StatefulWidget {
  const _OrderCouponsView({this.selectedId});
  final String? selectedId;

  @override
  State<_OrderCouponsView> createState() => _OrderCouponsViewState();
}

class _OrderCouponsViewState extends State<_OrderCouponsView> {
  late String? _selectedId = widget.selectedId;

  void _confirm() {
    final coupons = _availableCoupons();
    CouponEntity? chosen;
    for (final c in coupons) {
      if (c.id == _selectedId) {
        chosen = c;
        break;
      }
    }
    context.pop(chosen);
  }

  List<CouponEntity> _availableCoupons() =>
      context.read<CouponsCubit>().state.available;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(JameiaIcons.back, size: 20, color: AppColors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'coupons.select_coupon'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<CouponsCubit, CouponsState>(
          builder: (context, state) {
            return switch (state.status) {
              CouponsStatus.loaded => _list(context, state),
              _ => const Skeletonized(loading: true, child: CouponsSkeleton()),
            };
          },
        ),
      ),
      bottomNavigationBar: _ConfirmBar(onConfirm: _confirm),
    );
  }

  Widget _list(BuildContext context, CouponsState state) {
    final coupons = state.available;
    if (coupons.isEmpty) {
      return const _NoCouponsView();
    }
    return ContentClamp(
      child: ListView.builder(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.pageMargin,
          end: AppSpacing.pageMargin,
          top: AppSpacing.s12,
          bottom: AppSpacing.s12,
        ),
        // +1 trailing row: the explicit "don't use a coupon" option.
        itemCount: coupons.length + 1,
        itemBuilder: (context, i) {
          if (i == coupons.length) {
            return StaggerEntrance(
              index: i,
              child: _NoCouponOption(
                selected: _selectedId == null,
                onTap: () => setState(() => _selectedId = null),
              ),
            );
          }
          final c = coupons[i];
          return StaggerEntrance(
            index: i,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
              child: _CouponTicketTile(
                coupon: c,
                selected: _selectedId == c.id,
                onTap: () => setState(() => _selectedId = c.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Selectable coupon ticket — the signature Jameia stub-cut voucher card with a
/// radio indicator. The left "stub" carries the discount amount; the right body
/// carries the title/conditions/expiry.
class _CouponTicketTile extends StatelessWidget {
  const _CouponTicketTile({
    required this.coupon,
    required this.selected,
    required this.onTap,
  });

  final CouponEntity coupon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
      // whole ticket gives the subtle press feel.
      child: PressScale(
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r4),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r4),
            onTap: onTap,
            child: AnimatedContainer(
              duration: MotionGuard.duration(context, AppMotion.fast),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.r4),
                border: Border.all(
                  color: selected ? AppColors.primaryDark : AppColors.divider,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AmountStub(amount: coupon.amount),
                    Expanded(child: _TicketBody(coupon: coupon)),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.s12,
                      ),
                      child: _RadioDot(selected: selected),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountStub extends StatelessWidget {
  const _AmountStub({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.accent1Light,
        borderRadius: BorderRadiusDirectional.horizontal(
          start: Radius.circular(AppRadius.r4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${Formatters.currency} ',
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.accent1,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                TextSpan(
                  text: Formatters.amount(amount),
                  style: AppTextStyles.digits(22).copyWith(
                    color: AppColors.accent1,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'coupons.off'.tr(),
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.accent1,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({required this.coupon});
  final CouponEntity coupon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coupon.title,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (coupon.subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              coupon.subtitle,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: [
              if (coupon.minSpend > 0) ...[
                Text(
                  'coupons.min_amount'.tr(
                    namedArgs: {'value': Formatters.price(coupon.minSpend)},
                  ),
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
              Flexible(
                child: Text(
                  coupon.expiry,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Don't use a coupon" radio row.
class _NoCouponOption extends StatelessWidget {
  const _NoCouponOption({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
    // whole row gives the subtle press feel.
    return PressScale(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          onTap: onTap,
          child: AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r4),
              border: Border.all(
                color: selected ? AppColors.primaryDark : AppColors.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'coupons.dont_use'.tr(),
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ),
                _RadioDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand-yellow filled radio dot (Jameia selection style).
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.disabledText,
          width: 1.5,
        ),
      ),
      child: PopScale(
        popKey: selected,
        child: selected
            ? const Icon(
                JameiaIcons.confirm,
                size: 14,
                color: AppColors.brandForeground,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Sticky confirm bar that pops the chosen coupon.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: AppShadows.medium,
        ),
        // NOTE: do NOT wrap this in ContentClamp — its inner Align expands to
        // fill the loose height a bottomNavigationBar gives, which balloons the
        // bar to full-screen (button pinned top-centre, body squeezed to zero).
        // A full-width CTA matches the app's other sticky bottom bars anyway.
        child: AppButton(label: 'coupons.confirm'.tr(), onPressed: onConfirm),
      ),
    );
  }
}

class _NoCouponsView extends StatelessWidget {
  const _NoCouponsView();

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.local_activity_outlined,
      message: 'coupons.none_for_order'.tr(),
    );
  }
}
