import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/light_sweep.dart';

/// The paywall's pill CTA — the app's primary button look (brand green,
/// white bold label, press-scale, tap haptic) plus what the paywall needs:
/// the label flips when it changes (another plan), shrinks instead of
/// overflowing, and a band of light sweeps across the pill now and then while
/// it is enabled. [holding] keeps the active look while the page's busy
/// overlay covers a submit: no tap, no sweep, no grey flash.
class ProCtaButton extends StatelessWidget {
  const ProCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.holding = false,
  });

  static const double _height = AppSize.s52;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool holding;

  @override
  Widget build(BuildContext context) {
    final press = onPressed;
    final active = enabled && !holding && press != null;
    final looksActive = active || holding;
    // One node for screen readers: a button (the label comes from the Text),
    // announced as disabled while it cannot be pressed.
    return Semantics(
      container: true,
      button: true,
      enabled: active,
      child: PressScale(
        enabled: active,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: _radius,
            child: LightSweep(
              active: active,
              child: Material(
                color: looksActive ? AppColors.primary : AppColors.divider,
                child: InkWell(
                  onTap: active
                      ? () {
                          Haptics.tap();
                          press();
                        }
                      : null,
                  child: SizedBox(
                    height: _height,
                    width: double.infinity,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        child: FlipValue(
                          flipKey: label,
                          alignment: AlignmentDirectional.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: AppTextStyles.headingMedium.copyWith(
                                color: looksActive
                                    ? AppColors.brandForeground
                                    : AppColors.tertiaryText,
                                fontWeight: AppTextStyles.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
