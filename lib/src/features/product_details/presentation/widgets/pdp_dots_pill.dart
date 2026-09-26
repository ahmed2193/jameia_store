import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'pdp_dots_painter.dart';

/// The paging dots of the product photos, on a small translucent grey pill:
/// the photo shown is the light dot, the others dimmer. Shared by the
/// product page's gallery and the full-screen viewer. Nothing for a single
/// photo — one photo is not a pager.
class PdpDotsPill extends StatelessWidget {
  const PdpDotsPill({super.key, required this.controller, required this.count});

  final PageController controller;
  final int count;

  static const double _dot = AppSize.s6;
  static const double _gap = AppSpacing.s4;

  /// The resting dots are the lit white, dimmed to this.
  static const double _restingAlpha = 0.55;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.dotInactive,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s4,
          ),
          child: CustomPaint(
            size: Size(
              PdpDotsPainter.widthOf(count, dot: _dot, gap: _gap),
              _dot,
            ),
            painter: PdpDotsPainter(
              controller: controller,
              count: count,
              dot: _dot,
              gap: _gap,
              lit: AppColors.white,
              resting: AppColors.white.withValues(alpha: _restingAlpha),
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}
