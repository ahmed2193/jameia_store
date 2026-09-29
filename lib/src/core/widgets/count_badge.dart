import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/change_bump.dart';
import '../motion/fly_to_cart.dart';
import '../motion/motion.dart';
import '../motion/pop_switcher.dart';
import '../motion/rolling_number.dart';
import '../motion/tint_flash.dart';
import '../responsive/app_size.dart';

/// THE count pill (docs/motion §9.3, D15 / D16; CC-06): a coloured pill with
/// a tabular count, `99+` above [cap], laid out left-to-right in every
/// language. Every cart, unread and coupon badge is one of these; the host
/// passes only its colours and size.
///
/// Motion: the first build is static (a badge never pops on mount or on a
/// tab visit). While on screen, a change bumps the pill once (`ChangeBump`)
/// and rolls its number (`RollingNumber`, direction from the delta); 0 → n
/// pops the pill in and n → 0 lets it fade out (`PopSwitcher`) instead of
/// cutting. With [landsWithFlight] a rise waits for the add-to-cart flight
/// in the air to LAND (`FlyToCart.landings`) before it shows, so the count
/// changes where the product arrives. Reduced motion → no flight, no bump:
/// the pill tints once (`TintFlash`, fast) as the number changes.
class CountBadge extends StatefulWidget {
  const CountBadge({
    super.key,
    required this.count,
    required this.color,
    this.textColor = AppColors.white,
    this.textStyle,
    this.borderColor,
    this.borderWidth = AppSize.s1,
    this.minSize = AppSize.s16,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.s4,
    ),
    this.margin = EdgeInsetsDirectional.zero,
    this.cap = defaultCap,
    this.landsWithFlight = false,
  });

  /// Counts above this read `99+`.
  static const int defaultCap = 99;

  /// How strongly the reduced-motion tint washes over the pill.
  static const double _tintAlpha = 0.45;

  final int count;
  final Color color;
  final Color textColor;

  /// Size and weight of the count; bold [AppTextStyles.captionSmall] when
  /// null. [textColor] and tabular figures are applied on top.
  final TextStyle? textStyle;

  /// A ring around the pill (null = none).
  final Color? borderColor;
  final double borderWidth;

  /// The pill is at least this wide and tall (a circle for one digit).
  final double minSize;
  final EdgeInsetsGeometry padding;

  /// Space around the pill, only while it shows (a gap after a label that
  /// should not stay behind at zero).
  final EdgeInsetsGeometry margin;
  final int cap;

  /// A rise waits for the add-to-cart flight in the air to land.
  final bool landsWithFlight;

  @override
  State<CountBadge> createState() => _CountBadgeState();
}

class _CountBadgeState extends State<CountBadge> {
  /// The count on the pill: [CountBadge.count], or the one before it while a
  /// rise waits for its flight.
  late int _shown = widget.count;

  @override
  void initState() {
    super.initState();
    if (widget.landsWithFlight) FlyToCart.landings.addListener(_onLanding);
  }

  @override
  void didUpdateWidget(CountBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.landsWithFlight != widget.landsWithFlight) {
      if (widget.landsWithFlight) {
        FlyToCart.landings.addListener(_onLanding);
      } else {
        FlyToCart.landings.removeListener(_onLanding);
      }
    }
    final count = widget.count;
    if (count == _shown) return;
    final waits =
        widget.landsWithFlight && count > _shown && FlyToCart.airborne > 0;
    if (!waits) _shown = count;
  }

  void _onLanding() {
    if (!mounted || _shown == widget.count) return;
    setState(() => _shown = widget.count);
  }

  @override
  void dispose() {
    FlyToCart.landings.removeListener(_onLanding);
    super.dispose();
  }

  String _format(num value) =>
      value > widget.cap ? '${widget.cap}+' : '${value.round()}';

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final visible = shown > 0;
    final radius = BorderRadius.circular(AppRadius.pill);
    final border = widget.borderColor;
    final style =
        (widget.textStyle ??
                AppTextStyles.captionSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ))
            .copyWith(
              color: widget.textColor,
              fontFeatures: AppTextStyles.tabular,
            );
    return PopSwitcher(
      stateKey: visible,
      child: visible
          ? Padding(
              padding: widget.margin,
              child: ChangeBump(
                value: shown,
                child: TintFlash<int>(
                  value: shown,
                  color: AppColors.white,
                  peakAlpha: CountBadge._tintAlpha,
                  over: true,
                  reducedOnly: true,
                  duration: AppMotion.fast,
                  borderRadius: radius,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: widget.minSize,
                      minHeight: widget.minSize,
                    ),
                    padding: widget.padding,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: radius,
                      border: border == null
                          ? null
                          : Border.all(
                              color: border,
                              width: widget.borderWidth,
                            ),
                    ),
                    child: RollingNumber(
                      value: shown,
                      format: _format,
                      style: style,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
