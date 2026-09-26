import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/rolling_number.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shelf_marker_painter.dart';

/// The price at the start of the buy bar, bold and large: what the
/// selection costs — per piece, or the line total once it is in the cart —
/// its changed digits rolling. On a [deal] the lime marker draws itself
/// under it (again for another [option]) and the struck total sits below; a
/// Pro member paying less sees the regular total struck. All amounts arrive
/// decided by the domain (`ProductDetail`).
class PdpBarPrice extends StatefulWidget {
  const PdpBarPrice({
    super.key,
    required this.amountKd,
    this.struckKd,
    this.deal = false,
    this.option,
  });

  final double amountKd;

  /// The struck total, or `null`.
  final double? struckKd;

  /// The struck total is a deal's price before (the lime marker shows).
  final bool deal;

  /// What is priced (the chosen option); another one draws the marker again,
  /// a new quantity only rolls the digits.
  final Object? option;

  @override
  State<PdpBarPrice> createState() => _PdpBarPriceState();
}

class _PdpBarPriceState extends State<PdpBarPrice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marker = AnimationController(
    vsync: this,
    duration: AppMotion.drawOn,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _draw();
  }

  @override
  void didUpdateWidget(PdpBarPrice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option != widget.option || oldWidget.deal != widget.deal) {
      _draw();
    }
  }

  void _draw() {
    if (MotionGuard.reduced(context)) {
      _marker.value = 1;
    } else {
      _marker.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _marker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final struck = widget.struckKd;
    final amount = RollingNumber(
      value: widget.amountKd,
      format: (value) => Formatters.price(value.toDouble()),
      style: AppTextStyles.displayMedium.copyWith(
        color: AppColors.primaryText,
        fontWeight: AppTextStyles.bold,
      ),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.deal)
            CustomPaint(
              painter: ShelfMarkerPainter(
                progress: _marker,
                color: AppColors.proLime,
                textDirection: Directionality.of(context),
              ),
              child: amount,
            )
          else
            amount,
          if (struck != null)
            Text(
              Formatters.price(struck),
              maxLines: 1,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.tertiaryText,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.tertiaryText,
              ),
            ),
        ],
      ),
    );
  }
}
