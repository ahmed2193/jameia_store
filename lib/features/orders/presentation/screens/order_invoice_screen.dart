import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../domain/entities/order.dart';
import '../util/order_display.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/order_invoice_cubit.dart';

/// KeeTa invoice / e-receipt screen (`mach_pro_sailor_c_order_invoice`).
///
/// 1:1 clone of the smallest order-cluster page: a clean e-receipt for the most
/// recent order — shop header, itemised list + totals (from
/// [KeetaRepository.orders] `.first`), an invoice-title chooser row (the live app
/// drives this through the `CHOOSE_INVOICE_TITLE` host bridge; here it toggles
/// between *Personal* and a *Company* title via a styled picker sheet), and the
/// download / share action bar (`save-file` + `share` host bridges).
///
/// [KeetaOrder] carries no tax/seller fields, so the e-invoice meta rows use the
/// fixed demo values KeeTa shows for a personal e-receipt.
class OrderInvoiceScreen extends StatelessWidget {
  const OrderInvoiceScreen({super.key, this.orderId});

  /// Optional order id; defaults to the most recent order (`orders.first`).
  final String? orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderInvoiceCubit>()..load(orderId),
      child: const _OrderInvoiceView(),
    );
  }
}

class _OrderInvoiceView extends StatelessWidget {
  const _OrderInvoiceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(KeetaIcons.back, size: 20),
          color: AppColors.primaryText,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'orders.e_invoice'.tr(),
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: BlocBuilder<OrderInvoiceCubit, OrderInvoiceState>(
        builder: (context, state) {
          return switch (state.status) {
            OrderInvoiceStatus.initial ||
            OrderInvoiceStatus.loading => const AppLoader(),
            OrderInvoiceStatus.error => ErrorView(
              message: 'orders.no_invoice'.tr(),
              onRetry: () => Navigator.maybePop(context),
            ),
            OrderInvoiceStatus.loaded => _Loaded(state: state),
          };
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final OrderInvoiceState state;

  @override
  Widget build(BuildContext context) {
    final order = state.order!;
    return ContentClamp(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.pageMargin),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[
                // Receipt + meta cards cascade in via the shared StaggerEntrance
                // primitive (reduced-motion → instant).
                StaggerEntrance(
                  index: 0,
                  // ── The receipt card (zig-zag torn-edge top + bottom). ──
                  child: _ReceiptCard(order: order),
                ),
                const SizedBox(height: AppSpacing.s16),
                // ── Invoice-title chooser. ──
                StaggerEntrance(
                  index: 1,
                  child: _SectionCard(
                    title: 'orders.invoice_details'.tr(),
                    child: _InvoiceTitleRow(title: state.invoiceTitle),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                // ── E-invoice meta. ──
                StaggerEntrance(
                  index: 2,
                  child: _SectionCard(
                    title: 'orders.e_invoice_info'.tr(),
                    child: const _InvoiceMeta(),
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Receipt card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: PhysicalShape(
        clipper: const _ReceiptClipper(),
        color: AppColors.white,
        elevation: 0,
        shadowColor: AppColors.overlayDivider,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _ReceiptBrand(),
              const SizedBox(height: AppSpacing.s16),
              _ReceiptHeader(order: order),
              const SizedBox(height: AppSpacing.s16),
              const _DashedDivider(),
              const SizedBox(height: AppSpacing.s12),
              // Items — short fixed-length list, safe in a Column.
              for (final item in order.items) ...[
                _ReceiptItemRow(item: item),
                const SizedBox(height: AppSpacing.s10),
              ],
              const SizedBox(height: AppSpacing.s2),
              const _DashedDivider(),
              const SizedBox(height: AppSpacing.s12),
              _ReceiptTotals(order: order),
              const SizedBox(height: AppSpacing.s16),
              const _DashedDivider(),
              const SizedBox(height: AppSpacing.s16),
              const _ReceiptActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptBrand extends StatelessWidget {
  const _ReceiptBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            KeetaIcons.confirmReceipt,
            size: 26,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'orders.payment_receipt'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'orders.thank_you_order'.tr(),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ],
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        KeetaImage.circle(url: order.shopLogo, size: 40),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                order.displayShopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '#${order.id.toUpperCase()} · ${order.displayDate}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ],
          ),
        ),
        _StatusPill(status: order.status),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status == 'completed' || status == 'delivering';
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: paid ? AppColors.successBg : AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        paid ? 'orders.paid'.tr() : 'orders.pending'.tr(),
        style: AppTextStyles.captionSmall.copyWith(
          color: paid ? AppColors.success : AppColors.tertiaryText,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 28,
          child: Text(
            '${item.qty}×',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ),
        Expanded(child: Text(item.displayName, style: AppTextStyles.bodyLarge)),
        const SizedBox(width: AppSpacing.s8),
        Text(
          Formatters.price(item.price * item.qty),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _ReceiptTotals extends StatelessWidget {
  const _ReceiptTotals({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    // [KeetaOrder.total] is the charged amount; derive demo subtotal + fees so
    // the receipt reads like a real KeeTa breakdown (subtotal + fee + tax = total).
    const deliveryFee = 6.0;
    final taxable = (order.total - deliveryFee).clamp(0.0, order.total);
    final subtotal = taxable / 1.15;
    final tax = taxable - subtotal;

    return Column(
      children: <Widget>[
        _TotalLine(
          label: 'orders.subtotal'.tr(),
          value: Formatters.price(subtotal),
        ),
        const SizedBox(height: AppSpacing.s8),
        _TotalLine(
          label: 'orders.delivery_fee'.tr(),
          value: Formatters.price(deliveryFee),
        ),
        const SizedBox(height: AppSpacing.s8),
        _TotalLine(label: 'orders.vat'.tr(), value: Formatters.price(tax)),
        const SizedBox(height: AppSpacing.s12),
        _TotalLine(
          label: 'orders.total_paid'.tr(),
          value: Formatters.price(order.total),
          emphasize: true,
        ),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasize
        ? AppTextStyles.headingSmall.copyWith(fontWeight: AppTextStyles.bold)
        : AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText);
    final valueStyle = emphasize
        ? AppTextStyles.headingMedium.copyWith(fontWeight: AppTextStyles.bold)
        : AppTextStyles.bodyLarge;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ── Receipt action bar (download + share host bridges) ───────────────────────

class _ReceiptActions extends StatelessWidget {
  const _ReceiptActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppOutlineButton(
            label: 'orders.share'.tr(),
            height: 50,
            onPressed: () => _toast(context, 'orders.receipt_shared'.tr()),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: AppButton(
            label: 'orders.download'.tr(),
            height: 50,
            radius: 25,
            onPressed: () => _toast(context, 'orders.saved_to_files'.tr()),
            trailing: const Icon(
              KeetaIcons.arrowDown,
              size: 16,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyLarge),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.black,
      ),
    );
}

// ── Invoice title chooser ─────────────────────────────────────────────────────

class _InvoiceTitleRow extends StatelessWidget {
  const _InvoiceTitleRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderInvoiceCubit>();
    // Passive PressScale (no onTap) adds a subtle press-shrink without competing
    // with the InkWell's ripple/gesture.
    return PressScale(
      child: InkWell(
        onTap: () => _openChooser(context, cubit),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          child: Row(
            children: <Widget>[
              const Icon(
                KeetaIcons.edit,
                size: 20,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'orders.invoice_title'.tr(),
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _invoiceTitleLabel(title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                KeetaIcons.arrowRight,
                size: 16,
                color: AppColors.tertiaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChooser(
    BuildContext context,
    OrderInvoiceCubit cubit,
  ) async {
    // Real KeeTa drives this as a CENTER modal (black 60% overlay + scale-in),
    // not a bottom sheet. [showKeetaDialog] supplies the fade + scale transition;
    // the dialog container itself uses a uniform 8dp radius (bundle class g6a017).
    final picked = await showKeetaDialog<String>(
      context,
      barrierLabel: 'orders.choose_invoice_title'.tr(),
      barrierColor: AppColors.overlayPrimary,
      pageBuilder: (_) => _InvoiceTitleDialog(current: title),
    );
    if (picked != null) cubit.chooseTitle(picked);
  }
}

class _InvoiceTitleDialog extends StatelessWidget {
  const _InvoiceTitleDialog({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r8)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'orders.choose_invoice_title'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            for (final option in _kInvoiceTitleOptions) ...[
              _TitleOption(
                label: _invoiceTitleLabel(option),
                selected: option == current,
                onTap: () => Navigator.pop(context, option),
              ),
              const ThinDivider(),
            ],
            const SizedBox(height: AppSpacing.s8),
          ],
        ),
      ),
    );
  }
}

class _TitleOption extends StatelessWidget {
  const _TitleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: selected
                      ? AppTextStyles.bold
                      : AppTextStyles.regular,
                ),
              ),
            ),
            if (selected)
              const Icon(
                KeetaIcons.confirm,
                size: 18,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}

/// Invoice-title option identities. These are stored/compared as stable keys
/// (the page cubit defaults to `'Personal'` and echoes the chosen value), so the
/// raw English values stay as the identity while [_invoiceTitleLabel] localizes
/// what the user sees.
const List<String> _kInvoiceTitleOptions = <String>[
  'Personal',
  'Company / Business',
];

/// Localized display label for an invoice-title [value], keeping the underlying
/// identity (matched against the cubit's stored title) stable.
String _invoiceTitleLabel(String value) {
  switch (value) {
    case 'Personal':
      return 'orders.title_personal'.tr();
    case 'Company / Business':
      return 'orders.title_company'.tr();
    default:
      return value;
  }
}

// ── E-invoice meta ────────────────────────────────────────────────────────────

class _InvoiceMeta extends StatelessWidget {
  const _InvoiceMeta();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _MetaRow(
          label: 'orders.invoice_type'.tr(),
          value: 'orders.invoice_type_value'.tr(),
        ),
        const SizedBox(height: AppSpacing.s8),
        _MetaRow(
          label: 'orders.invoice_status'.tr(),
          value: 'orders.invoice_status_value'.tr(),
        ),
        const SizedBox(height: AppSpacing.s8),
        _MetaRow(
          label: 'orders.invoice_delivery'.tr(),
          value: 'orders.invoice_delivery_value'.tr(),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(value, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

// ── Shared section card shell ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          child,
        ],
      ),
    );
  }
}

// ── Dashed divider (receipt aesthetic) ────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      final next = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(next, y), paint);
      x = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

// ── Torn-edge receipt clipper (zig-zag top + bottom) ──────────────────────────

class _ReceiptClipper extends CustomClipper<Path> {
  const _ReceiptClipper();

  static const double _tooth = 9;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, _tooth);
    // Top zig-zag (start → end).
    var x = 0.0;
    var up = false;
    while (x < size.width) {
      x = (x + _tooth).clamp(0.0, size.width);
      path.lineTo(x, up ? 0 : _tooth);
      up = !up;
    }
    // Down the end edge.
    path.lineTo(size.width, size.height - _tooth);
    // Bottom zig-zag (end → start).
    x = size.width;
    up = false;
    while (x > 0) {
      x = (x - _tooth).clamp(0.0, size.width);
      path.lineTo(x, up ? size.height : size.height - _tooth);
      up = !up;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ReceiptClipper oldClipper) => false;
}
