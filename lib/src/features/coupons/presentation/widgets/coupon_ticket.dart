import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'coupon_fade.dart';
import 'coupon_perforation_painter.dart';
import 'coupon_ticket_clipper.dart';
import 'coupon_ticket_outline_painter.dart';
import 'coupon_ticket_shadow_painter.dart';

/// The coupon ticket shape: a white card on a soft shadow, the warm [stub]
/// on the start side, a punched perforation with two notches on the seam, and
/// the [body] beside it. [faded] paints the card, outline
/// and shadow in the spent-coupon greys ([CouponFade]; the stub and body take
/// their own flag). Mirrors under RTL.
class CouponTicket extends StatelessWidget {
  const CouponTicket({
    super.key,
    required this.stub,
    required this.body,
    this.faded = false,
  });

  final Widget stub;
  final Widget body;
  final bool faded;

  static const double stubWidth = AppSize.s96;
  static const double minHeight = AppSize.s110;
  static const double _notchRadius = AppSize.s9;
  static const double _cornerRadius = AppRadius.r3;
  static const double _holeRadius = AppSize.s2_5;
  static const double _holeGap = AppSize.s5;
  static const double _perforationWidth = AppSize.s8;
  static const double _stroke = AppSize.s1;
  static const double _blur = AppSize.s6;
  static const double _drop = AppSize.s3;
  static const double _shadowAlpha = 0.08;
  static final Color _shadow = AppColors.black.withValues(alpha: _shadowAlpha);

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final paper = CouponFade.of(AppColors.white, faded: faded);
    final clipper = CouponTicketClipper(
      stubWidth: stubWidth,
      notchRadius: _notchRadius,
      cornerRadius: _cornerRadius,
      rtl: rtl,
    );
    return CustomPaint(
      painter: CouponTicketShadowPainter(
        cornerRadius: _cornerRadius,
        color: CouponFade.of(_shadow, faded: faded),
        blurSigma: _blur,
        offsetY: _drop,
      ),
      foregroundPainter: CouponTicketOutlinePainter(
        stubWidth: stubWidth,
        notchRadius: _notchRadius,
        cornerRadius: _cornerRadius,
        rtl: rtl,
        color: CouponFade.of(AppColors.divider, faded: faded),
        strokeWidth: _stroke,
      ),
      child: ClipPath(
        clipper: clipper,
        child: ColoredBox(
          color: paper,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: stubWidth,
                  child: stub,
                ),
                PositionedDirectional(
                  start: stubWidth - _perforationWidth / 2,
                  top: 0,
                  bottom: 0,
                  width: _perforationWidth,
                  child: CustomPaint(
                    painter: CouponPerforationPainter(
                      color: paper,
                      inset: _notchRadius + AppSpacing.s4,
                      holeRadius: _holeRadius,
                      gap: _holeGap,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: stubWidth),
                  child: body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
