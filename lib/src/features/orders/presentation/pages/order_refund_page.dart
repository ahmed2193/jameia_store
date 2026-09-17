import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../domain/entities/order.dart';
import '../util/order_display.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/order_refund_cubit.dart';

/// Jameia refund-request screen (`mach_pro_sailor_c_order_refund`).
///
/// Sections (Jameia order): refund-reason radio list → per-item selection with a
/// quantity counter → problem-description text field → photo-evidence uploader →
/// refund-amount summary → sticky Submit (opens a success dialog).
class OrderRefundPage extends StatelessWidget {
  const OrderRefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderRefundCubit>(),
      child: const _OrderRefundView(),
    );
  }
}

/// Ordered refund-form sections — fed to [StaggerEntrance] for a cascading reveal.
const List<Widget> _sections = <Widget>[
  _ReasonSection(),
  _ItemSection(),
  _DescriptionSection(),
  _PhotoSection(),
  _RefundMethodTip(),
  _AmountSection(),
];

class _OrderRefundView extends StatelessWidget {
  const _OrderRefundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(JameiaIcons.back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'orders.request_refund'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<OrderRefundCubit, OrderRefundState>(
        buildWhen: (a, b) => a.status != b.status,
        builder: (context, state) {
          return switch (state.status) {
            OrderRefundStatus.initial ||
            OrderRefundStatus.loading => const AppLoader(),
            OrderRefundStatus.error => ErrorView(
              message: 'orders.could_not_load'.tr(),
              onRetry: () => Navigator.maybePop(context),
            ),
            OrderRefundStatus.loaded => ContentClamp(
              child: CustomScrollView(
                slivers: [
                  // Each refund section cascades in via the shared StaggerEntrance
                  // primitive (reduced-motion → instant), matching the app's list grammar.
                  for (final (i, section) in _sections.indexed) ...[
                    SliverToBoxAdapter(
                      child: StaggerEntrance(index: i, child: section),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: i == _sections.length - 1
                            ? AppSpacing.s24
                            : AppSpacing.s8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          };
        },
      ),
      bottomNavigationBar: const _SubmitBar(),
    );
  }
}

// ── White card scaffold shared by every section ──────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          child,
        ],
      ),
    );
  }
}

// ── 1. Refund reason radio list ──────────────────────────────────────────────
class _ReasonSection extends StatelessWidget {
  const _ReasonSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'orders.refund_reason_question'.tr(),
      child: BlocBuilder<OrderRefundCubit, OrderRefundState>(
        buildWhen: (a, b) => a.reason != b.reason,
        builder: (context, state) {
          final cubit = context.read<OrderRefundCubit>();
          return Column(
            children: [
              for (final reason in RefundReason.values)
                _ReasonTile(
                  reason: reason,
                  selected: state.reason == reason,
                  onTap: () => cubit.selectReason(reason),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Localized label for a [RefundReason]. The enum + its English `label` live in
/// the page cubit (not localized there); this maps each case to a translation
/// key for display while the enum value stays the identity.
String _refundReasonLabel(RefundReason reason) => switch (reason) {
  RefundReason.missingItem => 'orders.reason_missing_item'.tr(),
  RefundReason.wrongItem => 'orders.reason_wrong_item'.tr(),
  RefundReason.qualityIssue => 'orders.reason_quality'.tr(),
  RefundReason.lateDelivery => 'orders.reason_late_delivery'.tr(),
  RefundReason.other => 'orders.reason_other'.tr(),
};

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final RefundReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Passive PressScale (no onTap) gives the tap a subtle press-shrink without
    // competing with the InkWell's own ripple/gesture.
    return PressScale(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _refundReasonLabel(reason),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: selected
                        ? AppTextStyles.bold
                        : AppTextStyles.regular,
                  ),
                ),
              ),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // Shipped Jameia radio glyphs (order_status bundle): selected vs gray.
    return Image.asset(
      selected
          ? JameiaAssets.refundReasonSelected
          : JameiaAssets.refundReasonUnselected,
      width: 20,
      height: 20,
      fit: BoxFit.contain,
    );
  }
}

// ── 2. Per-item selection with quantity counter ──────────────────────────────
class _ItemSection extends StatelessWidget {
  const _ItemSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderRefundCubit, OrderRefundState>(
      buildWhen: (a, b) => a.selectedQty != b.selectedQty,
      builder: (context, state) {
        return _SectionCard(
          title: 'orders.which_items'.tr(),
          subtitle: 'orders.n_selected'.tr(
            namedArgs: {'count': '${state.selectedItemCount}'},
          ),
          child: Column(
            children: [
              for (var i = 0; i < state.order!.items.length; i++)
                _RefundItemRow(
                  item: state.order!.items[i],
                  selectedQty: state.selectedQty[i] ?? 0,
                  onAdd: () => context.read<OrderRefundCubit>().increment(i),
                  onRemove: () => context.read<OrderRefundCubit>().decrement(i),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RefundItemRow extends StatelessWidget {
  const _RefundItemRow({
    required this.item,
    required this.selectedQty,
    required this.onAdd,
    required this.onRemove,
  });

  final OrderItemEntity item;
  final int selectedQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = selectedQty > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 22,
            color: selected ? AppColors.primary : AppColors.disabledText,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  '${Formatters.price(item.price)} · ${'orders.ordered_qty'.tr(namedArgs: {'qty': '${item.qty}'})}',
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          QtyStepper(qty: selectedQty, onAdd: onAdd, onRemove: onRemove),
        ],
      ),
    );
  }
}

// ── 3. Problem description text field ─────────────────────────────────────────
class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection();

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'orders.describe_problem'.tr(),
      subtitle: 'orders.optional'.tr(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.mediumBackground,
          borderRadius: BorderRadius.circular(AppRadius.r6),
        ),
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
          onChanged: (v) => context.read<OrderRefundCubit>().setDescription(v),
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
          decoration: InputDecoration.collapsed(
            hintText: 'orders.describe_hint'.tr(),
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 4. Photo-evidence uploader (dummy add tiles) ─────────────────────────────
class _PhotoSection extends StatelessWidget {
  const _PhotoSection();

  static const int _maxPhotos = 6;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderRefundCubit, OrderRefundState>(
      buildWhen: (a, b) => a.photoCount != b.photoCount,
      builder: (context, state) {
        final cubit = context.read<OrderRefundCubit>();
        return _SectionCard(
          title: 'orders.add_photos'.tr(),
          subtitle: '${state.photoCount}/$_maxPhotos',
          child: Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < state.photoCount; i++)
                _PhotoTile(onDelete: () => cubit.removePhoto(i)),
              if (state.photoCount < _maxPhotos)
                _AddPhotoTile(onTap: cubit.addPhoto),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.onDelete});
  final VoidCallback onDelete;

  static const double _size = 76;

  void _openViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.88),
      builder: (_) => const _PhotoViewerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _openViewer(context),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: AppColors.smallBackground,
                borderRadius: BorderRadius.circular(AppSize.r8),
              ),
              child: const Icon(
                JameiaIcons.image,
                color: AppColors.disabledText,
                size: 30,
              ),
            ),
          ),
          PositionedDirectional(
            top: -6,
            end: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.overlayPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  JameiaIcons.close,
                  color: AppColors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen zoom viewer shown when a photo tile is tapped.
///
/// Uses [InteractiveViewer] for pinch-to-zoom / pan. A close button sits in
/// the top-right corner so the user can dismiss without swiping back.
class _PhotoViewerDialog extends StatelessWidget {
  const _PhotoViewerDialog();

  @override
  Widget build(BuildContext context) {
    final safePad = MediaQuery.paddingOf(context);
    return Material(
      color: AppColors.black.withValues(alpha: 0.88),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // InteractiveViewer for pinch-zoom & pan
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                margin: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s24,
                  vertical: safePad.top + AppSpacing.s48,
                ),
                decoration: BoxDecoration(
                  color: AppColors.smallBackground,
                  borderRadius: BorderRadius.circular(AppSize.r8),
                ),
                child: const AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                    child: Icon(
                      JameiaIcons.image,
                      color: AppColors.disabledText,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Close button — top-end corner
          PositionedDirectional(
            top: safePad.top + AppSpacing.s8,
            end: AppSpacing.s12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  JameiaIcons.close,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.mediumBackground,
          borderRadius: BorderRadius.circular(AppSize.r8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              JameiaIcons.camera,
              color: AppColors.tertiaryText,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'orders.add'.tr(),
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4b. Refund method preference tip ─────────────────────────────────────────
class _RefundMethodTip extends StatelessWidget {
  const _RefundMethodTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s14,
      ),
      child: Row(
        children: [
          Image.asset(
            JameiaAssets.refundMethodSelected,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              'orders.refund_to_original'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          GestureDetector(
            onTap: () {},
            child: Text(
              'orders.learn_more'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.link,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. Refund-amount summary ─────────────────────────────────────────────────
class _AmountSection extends StatelessWidget {
  const _AmountSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderRefundCubit, OrderRefundState>(
      buildWhen: (a, b) =>
          a.refundAmount != b.refundAmount || a.order != b.order,
      builder: (context, state) {
        return _SectionCard(
          title: 'orders.refund_amount'.tr(),
          child: Column(
            children: [
              _AmountRow(
                label: 'orders.items_selected'.tr(),
                value: '${state.selectedItemCount}',
              ),
              const SizedBox(height: AppSpacing.s8),
              _AmountRow(
                label: 'orders.order_total'.tr(),
                value: Formatters.price(state.order!.total),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: ThinDivider(),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'orders.estimated_refund'.tr(),
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.price(state.refundAmount),
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.finalPrice,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  const Icon(
                    JameiaIcons.info,
                    size: 14,
                    color: AppColors.tertiaryText,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Text(
                      'orders.refund_return_note'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
          value,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
        ),
      ],
    );
  }
}

// ── 6. Sticky submit bar → success dialog ────────────────────────────────────
class _SubmitBar extends StatelessWidget {
  const _SubmitBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderRefundCubit, OrderRefundState>(
      buildWhen: (a, b) =>
          a.canSubmit != b.canSubmit || a.refundAmount != b.refundAmount,
      builder: (context, state) {
        return SafeArea(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: AppButton(
              label: state.canSubmit
                  ? '${'orders.submit'.tr()} · ${Formatters.price(state.refundAmount)}'
                  : 'orders.submit_refund'.tr(),
              enabled: state.canSubmit,
              onPressed: state.canSubmit
                  ? () {
                      context.read<OrderRefundCubit>().submit();
                      _showSuccess(
                        context,
                        state.refundAmount,
                        state.order!.id,
                      );
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _showSuccess(BuildContext context, double amount, String orderId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _RefundSuccessDialog(
        amount: amount,
        onDone: () {
          Navigator.of(dialogContext).pop();
          // Land on the refund-progress (detail) screen, replacing the request
          // form so Back returns to the order — matching Jameia's refund nav graph
          // (order_detail/order_status → refund request → refund progress).
          context.pushReplacement(Routes.orderRefundDetail, extra: orderId);
        },
      ),
    );
  }
}

class _RefundSuccessDialog extends StatelessWidget {
  const _RefundSuccessDialog({required this.amount, required this.onDone});

  final double amount;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(JameiaIcons.confirm, size: 56, color: AppColors.success),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'orders.refund_requested'.tr(),
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'orders.refund_requested_body'.tr(
                namedArgs: {'amount': Formatters.price(amount)},
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppButton(label: 'orders.done'.tr(), onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
