import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/branded_loader.dart';
import '../../../../core/widgets/light_sweep.dart';

/// The paywall's pill CTA — the app's primary button look (brand green,
/// white bold label, press-scale, tap haptic) plus what the paywall needs:
/// the label flips when it changes (another plan), shrinks instead of
/// overflowing, and a band of light sweeps across the pill now and then while
/// it is enabled. [loading] swaps the label for the inline loader.
class ProCtaButton extends StatelessWidget {
  const ProCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
  });

  static const double _height = AppSize.s52;
  static const double _loaderSize = AppSize.s22;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final press = onPressed;
    final active = enabled && !loading && press != null;
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
                color: active ? AppColors.primary : AppColors.divider,
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
                      child: loading
                          ? const BrandedLoader.inline(
                              size: _loaderSize,
                              color: AppColors.brandForeground,
                            )
                          : Padding(
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
                                      color: active
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
