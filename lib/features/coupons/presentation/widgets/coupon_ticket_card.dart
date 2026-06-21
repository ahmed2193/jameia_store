import 'package:flutter/material.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';

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

  final Coupon coupon;
  final CouponStatus status;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final enabled = status == CouponStatus.available;
    return RepaintBoundary(
      child: SizedBox(
        height: 108,
        child: Stack(
          children: [
            // Ticket body (clipped so the notch overlays read as cut-outs).
            ClipPath(
              clipper: _TicketClipper(),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r4),
                ),
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
          ],
        ),
      ),
    );
  }
}

/// Status drives the right-side action affordance + dimming.
enum CouponStatus { available, used, expired }

// ── Left value block ─────────────────────────────────────────────────────────
class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.coupon, required this.enabled});
  final Coupon coupon;
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
                  style: AppTextStyles.headingSmall
                      .copyWith(color: fg, fontWeight: AppTextStyles.bold),
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
            'Min ${Formatters.amount(coupon.minSpend)}',
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

  final Coupon coupon;
  final CouponStatus status;
  final bool enabled;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        enabled ? AppColors.primaryText : AppColors.tertiaryText;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12, AppSpacing.s12, AppSpacing.s10, AppSpacing.s12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(
                      color: titleColor, fontWeight: AppTextStyles.bold),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  coupon.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText),
                ),
                const SizedBox(height: AppSpacing.s6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.tertiaryText),
                    const SizedBox(width: AppSpacing.s4),
                    Flexible(
                      child: Text(
                        coupon.expiry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionSmall
                            .copyWith(color: AppColors.tertiaryText),
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
      return Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.r1),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r1),
          onTap: onUse,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
            child: Text('Use',
                style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.brandForeground,
                    fontWeight: AppTextStyles.bold)),
          ),
        ),
      );
    }
    // Used / Expired → muted outline stamp.
    final label = status == CouponStatus.used ? 'Used' : 'Expired';
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.disabledText, width: 1.2),
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(label,
          style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.disabledText, fontWeight: AppTextStyles.bold)),
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
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(_radius)));

    // Carve a circular notch on each side of the perforation seam.
    final seam = _valueWidth;
    final hole = Path()
      ..addOval(Rect.fromCircle(center: Offset(seam, notchY), radius: _notch));
    return Path.combine(PathOperation.difference, path, hole);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => false;
}
