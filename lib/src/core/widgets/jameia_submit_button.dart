import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/fade_through_switcher.dart';
import '../motion/haptics.dart';
import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import '../motion/spring_curve.dart';
import '../responsive/app_size.dart';
import 'branded_loader.dart';
import 'ready_wipe.dart';
import 'sticker_text.dart';

enum _SubmitPhase { label, loading, success }

/// The primary pill of a screen whose goal is one submit (place order, apply
/// a coupon, send a review): brand green, bold white label, press-scale and
/// tap haptic, and label ↔ loader ↔ check swapped through a fade-through at a
/// FIXED width. The pill stays green while loading and on success (the loader
/// stays visible) and the phase is announced. A tap on the disabled pill
/// reports [onBlocked] so the page can say why.
///
/// [sticker]: the active label is drawn in the sticker type of the buy
/// buttons (white letters, dark rim — [StickerText]) at the same size; the
/// disabled label stays plain grey.
///
/// [holding]: the pill keeps its active look (green, sticker label) while a
/// moment passes that must not accept a tap (the order re-prices): taps do
/// nothing, there is no press scale and no [onBlocked], and it is announced
/// as disabled. So a re-price never flashes the pill grey.
///
/// [readyFlourish]: the fill is a [ReadyWipe] — when the pill turns green
/// after the first build, the green wipes in from the start edge and one
/// light band crosses it, and the grey label cross-fades into the sticker
/// label once. A [holding] cycle keeps the pill green, so it never replays.
///
/// Same look and behaviour as the auth flow's `AuthSubmitButton`, which can
/// move onto this one.
class JameiaSubmitButton extends StatelessWidget {
  const JameiaSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.success = false,
    this.successLabel,
    this.onBlocked,
    this.height = AppSize.s52,
    this.sticker = false,
    this.holding = false,
    this.readyFlourish = false,
  });

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

  /// Tap on the pill while it is disabled (not while loading / done /
  /// holding).
  final VoidCallback? onBlocked;
  final double height;

  /// Sticker label (see the class doc).
  final bool sticker;

  /// Active look, no taps (see the class doc).
  final bool holding;

  /// The ready wipe (see the class doc).
  final bool readyFlourish;

  static TextStyle _labelStyle({required bool active}) =>
      AppTextStyles.headingMedium.copyWith(
        color: active ? AppColors.brandForeground : AppColors.tertiaryText,
        fontWeight: AppTextStyles.bold,
      );

  @override
  Widget build(BuildContext context) {
    final press = onPressed;
    final active = enabled && !loading && !success && press != null;
    final phase = success
        ? _SubmitPhase.success
        : loading
        ? _SubmitPhase.loading
        : _SubmitPhase.label;
    final looksActive = active || (holding && phase == _SubmitPhase.label);
    final filled = looksActive || phase != _SubmitPhase.label;
    final content = switch (phase) {
      _SubmitPhase.label => Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
        ),
        // Long Arabic / large text shrinks instead of overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: sticker && looksActive
              ? StickerText(label, style: _labelStyle(active: true))
              : Text(
                  label,
                  maxLines: 1,
                  style: _labelStyle(active: looksActive),
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
    final blocked = !active && !holding && phase == _SubmitPhase.label
        ? onBlocked
        : null;
    final surface = Material(
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
          child: FadeThroughSwitcher(
            // With the flourish, the grey label and the sticker label are
            // two states: they cross-fade once when the pill turns green.
            stateKey: readyFlourish ? (phase, filled) : phase,
            child: content,
          ),
        ),
      ),
    );
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
            decoration: readyFlourish
                ? null
                : BoxDecoration(
                    color: filled ? AppColors.primary : AppColors.divider,
                    borderRadius: _radius,
                  ),
            child: readyFlourish
                ? ReadyWipe(
                    ready: filled,
                    readyColor: AppColors.primary,
                    idleColor: AppColors.divider,
                    borderRadius: _radius,
                    child: surface,
                  )
                : surface,
          ),
        ),
      ),
    );
  }
}
