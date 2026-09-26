import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/motion/spring_curve.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/branded_loader.dart';

enum _SubmitPhase { label, loading, success }

/// The auth flow's primary pill: brand green, bold white label, press-scale
/// and tap haptic like every CTA, plus the states a sign-in step needs —
/// label ↔ loader ↔ check swap through a fade-through at a FIXED width (no
/// per-frame relayout), and a tap on the disabled pill reports [onBlocked]
/// (the page explains why instead of ignoring the tap).
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.success = false,
    this.successLabel,
    this.onBlocked,
  });

  static const double height = AppSize.s52;
  static const double _loaderSize = AppSize.s22;
  static const double _checkSize = AppSize.s26;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;
  final bool success;

  /// Read out when the check replaces the label.
  final String? successLabel;

  /// Tap on the pill while it is disabled (not while loading / done).
  final VoidCallback? onBlocked;

  @override
  Widget build(BuildContext context) {
    final press = onPressed;
    final active = enabled && !loading && !success && press != null;
    final phase = success
        ? _SubmitPhase.success
        : loading
        ? _SubmitPhase.loading
        : _SubmitPhase.label;
    final filled = active || phase != _SubmitPhase.label;
    final content = switch (phase) {
      _SubmitPhase.label => Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
        ),
        // Long Arabic / large text shrinks instead of overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: AppTextStyles.headingMedium.copyWith(
              color: active
                  ? AppColors.brandForeground
                  : AppColors.tertiaryText,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ),
      ),
      _SubmitPhase.loading => Semantics(
        label: label,
        child: const BrandedLoader.inline(
          size: _loaderSize,
          color: AppColors.brandForeground,
        ),
      ),
      _SubmitPhase.success => PopScale.onMount(
        curve: AppSprings.snappy,
        duration: AppSprings.snappy.duration,
        child: Icon(
          Icons.check_rounded,
          size: _checkSize,
          color: AppColors.brandForeground,
          semanticLabel: successLabel,
        ),
      ),
    };
    final blocked = !active && phase == _SubmitPhase.label ? onBlocked : null;
    return Semantics(
      button: true,
      enabled: active,
      liveRegion: true,
      child: GestureDetector(
        onTap: blocked,
        child: PressScale(
          enabled: active,
          child: AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: AppMotion.signature,
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.divider,
              borderRadius: _radius,
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: _radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: active
                    ? () {
                        Haptics.tap();
                        press();
                      }
                    : null,
                child: Center(
                  child: FadeThroughSwitcher(stateKey: phase, child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
