import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/coupon.dart';
import '../util/coupon_display.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';

/// KeeTa coupon-ticket card: a left value block (amount + currency) joined to the
/// right info column (title, min-spend subtitle, expiry, Use button) by a vertical
/// dashed perforation with notch cut-outs at top & bottom — the classic voucher
/// look from `market_my_coupon_list`.
///
/// [enabled] dims the whole ticket for the Used / Expired tabs (greyed value
/// block, "Used"/"Expired" pill instead of the yellow Use button).
class CouponTicketCard extends StatelessWidget {
  const CouponTicketCard({
    super.key,
    required this.coupon,
    required this.status,
    this.onUse,
  });

  final CouponEntity coupon;
  final CouponStatus status;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final enabled = status == CouponStatus.available;
    return RepaintBoundary(
      // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
      // whole ticket gives the subtle press feel.
      child: PressScale(
        child: SizedBox(
          height: 108,
          child: Stack(
            children: [
              // Ticket body (clipped so the notch overlays read as cut-outs).
              ClipPath(
                clipper: _TicketClipper(),
                child: Material(
                  color: AppColors.white,
                  child: InkWell(
                    // Tapping a ticket opens its rule / detail sheet
                    // (KeeTa `coupon-rule-close` modal).
                    onTap: () => _showRuleSheet(context),
                    child: Row(
                      children: [
                        _ValueBlock(coupon: coupon, enabled: enabled),
                        const _Perforation(),
                        Expanded(
                          child: _InfoBlock(
                            coupon: coupon,
                            status: status,
                            enabled: enabled,
                            onUse: onUse,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRuleSheet(BuildContext context) {
    showKeetaBottomSheet<void>(
      context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.r4),
        ),
      ),
      builder: (sheetContext) => _CouponRuleSheet(coupon: coupon),
    );
  }
}

/// Status drives the right-side action affordance + dimming.
enum CouponStatus { available, used, expired }

// ── Left value block ─────────────────────────────────────────────────────────
class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.coupon, required this.enabled});
  final CouponEntity coupon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? AppColors.brandForeground : AppColors.tertiaryText;
    return Container(
      width: 104,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary : AppColors.smallBackground,
        borderRadius: const BorderRadiusDirectional.horizontal(
          start: Radius.circular(AppRadius.r4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 3),
                child: Text(
                  Formatters.currency,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: fg,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Formatters.amount(coupon.amount),
                    maxLines: 1,
                    style: AppTextStyles.digits(26).copyWith(color: fg),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'coupons.min_amount'.tr(
              namedArgs: {'value': Formatters.amount(coupon.minSpend)},
            ),
            style: AppTextStyles.captionSmall.copyWith(
              color: enabled ? AppColors.secondaryText : AppColors.tertiaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vertical dashed perforation ──────────────────────────────────────────────
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(color: AppColors.divider),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    double y = 10;
    while (y < size.height - 10) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Right info block ─────────────────────────────────────────────────────────
class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.coupon,
    required this.status,
    required this.enabled,
    required this.onUse,
  });

  final CouponEntity coupon;
  final CouponStatus status;
  final bool enabled;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled ? AppColors.primaryText : AppColors.tertiaryText;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s12,
        AppSpacing.s10,
        AppSpacing.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: titleColor,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  coupon.displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                Row(
                  children: [
                    Icon(
                      KeetaIcons.time,
                      size: 12,
                      color: AppColors.tertiaryText,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Flexible(
                      child: Text(
                        coupon.expiry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.tertiaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          _Action(status: status, onUse: onUse),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.status, required this.onUse});
  final CouponStatus status;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    if (status == CouponStatus.available) {
      return PressScale(
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.r5),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r5),
            onTap: onUse,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              child: Text(
                'coupons.use'.tr(),
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.brandForeground,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }
    // Used / Expired → muted outline stamp.
    final label = status == CouponStatus.used
        ? 'coupons.used'.tr()
        : 'coupons.expired'.tr();
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.disabledText, width: 1.2),
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.disabledText,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

// ── Ticket outline (rounded corners + side notches) ──────────────────────────
class _TicketClipper extends CustomClipper<Path> {
  static const double _radius = AppRadius.r4;
  static const double _notch = 6;
  static const double _valueWidth = 104;

  @override
  Path getClip(Size size) {
    final notchY = size.height / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(_radius),
        ),
      );

    // Carve a circular notch on each side of the perforation seam.
    final seam = _valueWidth;
    final hole = Path()
      ..addOval(Rect.fromCircle(center: Offset(seam, notchY), radius: _notch));
    return Path.combine(PathOperation.difference, path, hole);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => false;
}

// ── CouponEntity rule / detail sheet ───────────────────────────────────────────────
/// KeeTa `coupon-rule` modal: title, key conditions (discount, min-spend,
/// validity) and a static terms block, closed via the header X or the bottom
/// "Got it" CTA. Built entirely from the existing [CouponEntity] fields.
class _CouponRuleSheet extends StatelessWidget {
  const _CouponRuleSheet({required this.coupon});
  final CouponEntity coupon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.displayTitle,
                    style: AppTextStyles.headingLarge.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(KeetaIcons.close, size: 20),
                  color: AppColors.tertiaryText,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            _RuleRow(
              label: 'coupons.discount'.tr(),
              value: 'coupons.amount_off'.tr(
                namedArgs: {
                  'value':
                      '${Formatters.currency} ${Formatters.amount(coupon.amount)}',
                },
              ),
            ),
            _RuleRow(
              label: 'coupons.min_spend'.tr(),
              value:
                  '${Formatters.currency} ${Formatters.amount(coupon.minSpend)}',
            ),
            _RuleRow(label: 'coupons.valid_until'.tr(), value: coupon.expiry),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'coupons.terms'.tr(),
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'coupons.terms_body'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              label: 'coupons.got_it'.tr(),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
