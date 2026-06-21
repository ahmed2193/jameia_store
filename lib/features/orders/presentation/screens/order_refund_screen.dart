import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/order_refund_cubit.dart';

/// KeeTa refund-request screen (`mach_pro_sailor_c_order_refund`).
///
/// Sections (KeeTa order): refund-reason radio list → per-item selection with a
/// quantity counter → problem-description text field → photo-evidence uploader →
/// refund-amount summary → sticky Submit (opens a success dialog).
class OrderRefundScreen extends StatelessWidget {
  const OrderRefundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderRefundCubit(sl<KeetaRepository>()),
      child: const _OrderRefundView(),
    );
  }
}

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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Request a refund',
            style: AppTextStyles.headingLarge
                .copyWith(fontWeight: AppTextStyles.bold)),
        centerTitle: false,
      ),
      body: ContentClamp(
        child: CustomScrollView(
          slivers: const [
            SliverToBoxAdapter(child: _ReasonSection()),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),
            SliverToBoxAdapter(child: _ItemSection()),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),
            SliverToBoxAdapter(child: _DescriptionSection()),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),
            SliverToBoxAdapter(child: _PhotoSection()),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),
            SliverToBoxAdapter(child: _AmountSection()),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
          ],
        ),
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
          horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(title,
                    style: AppTextStyles.headingMedium
                        .copyWith(fontWeight: AppTextStyles.bold)),
              ),
              if (subtitle != null)
                Text(subtitle!,
                    style: AppTextStyles.captionLarge
                        .copyWith(color: AppColors.tertiaryText)),
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
      title: 'Why are you requesting a refund?',
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
        child: Row(
          children: [
            Expanded(
              child: Text(reason.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryText,
                      fontWeight:
                          selected ? AppTextStyles.bold : AppTextStyles.regular)),
            ),
            _Radio(selected: selected),
          ],
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
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.disabledText,
          width: selected ? 6 : 2,
        ),
        color: AppColors.white,
      ),
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
          title: 'Which items?',
          subtitle: '${state.selectedItemCount} selected',
          child: Column(
            children: [
              for (var i = 0; i < state.order.items.length; i++)
                _RefundItemRow(
                  item: state.order.items[i],
                  selectedQty: state.selectedQty[i] ?? 0,
                  onAdd: () => context.read<OrderRefundCubit>().increment(i),
                  onRemove: () =>
                      context.read<OrderRefundCubit>().decrement(i),
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

  final OrderItem item;
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
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.primaryText)),
                const SizedBox(height: AppSpacing.s2),
                Text(
                    '${Formatters.price(item.price)} · ordered ${item.qty}',
                    style: AppTextStyles.captionLarge
                        .copyWith(color: AppColors.tertiaryText)),
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
      title: 'Describe the problem',
      subtitle: 'Optional',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.mediumBackground,
          borderRadius: BorderRadius.circular(AppRadius.r4),
        ),
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
          onChanged: (v) =>
              context.read<OrderRefundCubit>().setDescription(v),
          style: AppTextStyles.bodyLarge
              .copyWith(color: AppColors.primaryText),
          decoration: InputDecoration.collapsed(
            hintText: 'Tell us what went wrong…',
            hintStyle: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.tertiaryText),
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
          title: 'Add photos',
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: AppColors.smallBackground,
              borderRadius: BorderRadius.circular(AppRadius.r4),
            ),
            child: const Icon(Icons.image_rounded,
                color: AppColors.disabledText, size: 30),
          ),
          PositionedDirectional(
            top: -6,
            end: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: AppColors.overlayPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.white, size: 14),
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
          borderRadius: BorderRadius.circular(AppRadius.r4),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_rounded,
                color: AppColors.tertiaryText, size: 24),
            SizedBox(height: AppSpacing.s4),
            Text('Add',
                style: TextStyle(
                    fontSize: 10, color: AppColors.tertiaryText)),
          ],
        ),
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
          title: 'Refund amount',
          child: Column(
            children: [
              _AmountRow(
                  label: 'Items selected',
                  value: '${state.selectedItemCount}'),
              const SizedBox(height: AppSpacing.s8),
              _AmountRow(
                  label: 'Order total',
                  value: Formatters.price(state.order.total)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: ThinDivider(),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('Estimated refund',
                        style: AppTextStyles.headingMedium
                            .copyWith(fontWeight: AppTextStyles.bold)),
                  ),
                  Text(Formatters.price(state.refundAmount),
                      style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.finalPrice,
                          fontWeight: AppTextStyles.bold)),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.tertiaryText),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Text(
                        'Refunds return to your original payment method within 3–5 days.',
                        style: AppTextStyles.captionLarge
                            .copyWith(color: AppColors.tertiaryText)),
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
          child: Text(label,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.secondaryText)),
        ),
        Text(value,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.primaryText)),
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
                  ? 'Submit · ${Formatters.price(state.refundAmount)}'
                  : 'Submit refund',
              enabled: state.canSubmit,
              onPressed: state.canSubmit
                  ? () => _showSuccess(context, state.refundAmount)
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _showSuccess(BuildContext context, double amount) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _RefundSuccessDialog(
        amount: amount,
        onDone: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).maybePop();
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
          borderRadius: BorderRadius.circular(AppRadius.r3)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 56, color: AppColors.success),
            const SizedBox(height: AppSpacing.s16),
            Text('Refund requested',
                style: AppTextStyles.headingLarge
                    .copyWith(fontWeight: AppTextStyles.bold)),
            const SizedBox(height: AppSpacing.s8),
            Text(
                'We’re reviewing your ${Formatters.price(amount)} refund. You’ll get an update shortly.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.secondaryText)),
            const SizedBox(height: AppSpacing.s24),
            AppButton(label: 'Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
