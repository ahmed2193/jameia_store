import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/coupons_cubit.dart';

/// KeeTa order-checkout coupon picker (`mach_pro_sailor_c_market_order_coupon_list`).
///
/// A radio-select list of available coupon tickets plus a "Don't use a coupon"
/// option, with a sticky [AppButton] that pops the chosen [Coupon] (or `null`)
/// back to the checkout screen. Page-scoped [CouponsCubit] is built inline.
class OrderCouponsScreen extends StatelessWidget {
  const OrderCouponsScreen({super.key, this.selectedId});

  /// Id of the coupon already applied to the order (pre-selects its radio).
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CouponsCubit(sl<KeetaRepository>())..load(),
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
    Coupon? chosen;
    for (final c in coupons) {
      if (c.id == _selectedId) {
        chosen = c;
        break;
      }
    }
    Navigator.pop(context, chosen);
  }

  List<Coupon> _availableCoupons() {
    final state = context.read<CouponsCubit>().state;
    return state is CouponsLoaded ? state.available : const <Coupon>[];
  }

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
          icon: const Icon(KeetaIcons.back, size: 20, color: AppColors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Select a coupon',
          style: AppTextStyles.headingLarge
              .copyWith(fontWeight: AppTextStyles.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<CouponsCubit, CouponsState>(
          builder: (context, state) {
            return switch (state) {
              CouponsLoading() => const AppLoader(),
              CouponsLoaded() => _list(context, state),
            };
          },
        ),
      ),
      bottomNavigationBar: _ConfirmBar(onConfirm: _confirm),
    );
  }

  Widget _list(BuildContext context, CouponsLoaded state) {
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
            return _NoCouponOption(
              selected: _selectedId == null,
              onTap: () => setState(() => _selectedId = null),
            );
          }
          final c = coupons[i];
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
            child: _CouponTicketTile(
              coupon: c,
              selected: _selectedId == c.id,
              onTap: () => setState(() => _selectedId = c.id),
            ),
          );
        },
      ),
    );
  }
}

/// Selectable coupon ticket — the signature KeeTa stub-cut voucher card with a
/// radio indicator. The left "stub" carries the discount amount; the right body
/// carries the title/conditions/expiry.
class _CouponTicketTile extends StatelessWidget {
  const _CouponTicketTile({
    required this.coupon,
    required this.selected,
    required this.onTap,
  });

  final Coupon coupon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
                        end: AppSpacing.s12),
                    child: _RadioDot(selected: selected),
                  ),
                ],
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
      width: 96,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s16),
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
                      fontWeight: AppTextStyles.bold),
                ),
                TextSpan(
                  text: Formatters.amount(amount),
                  style: AppTextStyles.digits(22).copyWith(
                      color: AppColors.accent1,
                      fontWeight: AppTextStyles.bold),
                ),
              ],
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'OFF',
            style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.accent1, fontWeight: AppTextStyles.bold),
          ),
        ],
      ),
    );
  }
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({required this.coupon});
  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coupon.title,
            style: AppTextStyles.headingSmall
                .copyWith(fontWeight: AppTextStyles.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (coupon.subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              coupon.subtitle,
              style: AppTextStyles.captionLarge
                  .copyWith(color: AppColors.secondaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: [
              if (coupon.minSpend > 0) ...[
                Text(
                  'Min ${Formatters.price(coupon.minSpend)}',
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.tertiaryText),
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
              Flexible(
                child: Text(
                  coupon.expiry,
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.tertiaryText),
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
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.r4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r4),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
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
                  "Don't use a coupon",
                  style: AppTextStyles.headingSmall
                      .copyWith(fontWeight: AppTextStyles.medium),
                ),
              ),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand-yellow filled radio dot (KeeTa selection style).
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.disabledText,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: AppColors.black)
          : null,
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
        child: ContentClamp(
          child: AppButton(label: 'Confirm', onPressed: onConfirm),
        ),
      ),
    );
  }
}

class _NoCouponsView extends StatelessWidget {
  const _NoCouponsView();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateView(
      icon: Icons.local_activity_outlined,
      message: 'No coupons available to apply to this order.',
    );
  }
}
