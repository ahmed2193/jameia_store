import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../../../core/responsive/app_size.dart';
import 'otp_slot_caret.dart';

/// What a digit slot is showing — each tone is one fill / border / ink set.
enum OtpSlotTone { empty, active, filled, error, success }

/// One painted digit box of the code input. Its colours cross-fade
/// ([AppMotion.fast], fixed-width border); a digit that lands springs in
/// from [_scaleFrom] with [AppSprings.calm] after [popDelay] (the paste
/// cascade), and only the slot whose digit changed moves.
class OtpCodeSlot extends StatefulWidget {
  const OtpCodeSlot({
    super.key,
    required this.digit,
    required this.tone,
    this.showCaret = false,
    this.popDelay = Duration.zero,
  });

  static const double maxWidth = AppSize.s52;
  static const double height = AppSize.s60;

  final String? digit;
  final OtpSlotTone tone;
  final bool showCaret;
  final Duration popDelay;

  @override
  State<OtpCodeSlot> createState() => _OtpCodeSlotState();
}

class _OtpCodeSlotState extends State<OtpCodeSlot>
    with SingleTickerProviderStateMixin {
  static const double _scaleFrom = 0.85;
  static const double _border = AppSize.s2;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  late final AnimationController _pop = AnimationController(
    vsync: this,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _pop,
    curve: AppSprings.calm,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: _scaleFrom,
    end: 1,
  ).animate(_curve);

  @override
  void didUpdateWidget(covariant OtpCodeSlot old) {
    super.didUpdateWidget(old);
    if (widget.digit == old.digit || widget.digit == null) return;
    if (MotionGuard.reduced(context)) {
      _pop.value = 1;
      return;
    }
    final spring = AppSprings.calm;
    final total = widget.popDelay + spring.duration;
    final start =
        widget.popDelay.inMicroseconds / total.inMicroseconds.toDouble();
    _curve.curve = Interval(start, 1, curve: spring);
    _pop
      ..duration = total
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (fill, border, ink) = switch (widget.tone) {
      OtpSlotTone.empty => (
        AppColors.smallBackground,
        AppColors.smallBackground,
        AppColors.primaryText,
      ),
      OtpSlotTone.active => (
        AppColors.white,
        AppColors.primary,
        AppColors.primaryText,
      ),
      OtpSlotTone.filled => (
        AppColors.white,
        AppColors.disabledText,
        AppColors.primaryText,
      ),
      OtpSlotTone.error => (
        AppColors.errorBg,
        AppColors.error,
        AppColors.error,
      ),
      OtpSlotTone.success => (
        AppColors.brandLightBg,
        AppColors.primary,
        AppColors.primaryDark,
      ),
    };
    final digit = widget.digit;
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      constraints: const BoxConstraints(maxWidth: OtpCodeSlot.maxWidth),
      height: OtpCodeSlot.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        border: Border.all(color: border, width: _border),
      ),
      child: digit != null
          ? FadeTransition(
              opacity: _curve,
              child: ScaleTransition(
                scale: _scale,
                child: Text(
                  digit,
                  style: AppTextStyles.displayMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                    color: ink,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
            )
          : widget.showCaret
          ? const OtpSlotCaret()
          : null,
    );
  }
}
