import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// White outlined sign-in pill with the provider's logo at its start and a
/// bold label centred on the whole pill (the phone step's primary is the
/// green pill above it).
class LoginSocialButton extends StatelessWidget {
  const LoginSocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const double _height = AppSize.s52;
  static const double _logo = AppSize.s24;
  static const double _pressedScale = 0.97;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Passive press-scale (no onTap) so the InkWell keeps owning the gesture +
    // ripple while the whole pill still dips under the finger.
    return PressScale(
      pressedScale: _pressedScale,
      child: Material(
        color: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(color: AppColors.disabledText),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s20,
              ),
              child: Row(
                children: [
                  Image.asset(
                    icon,
                    width: _logo,
                    height: _logo,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: AppTextStyles.headingMedium.copyWith(
                            fontWeight: AppTextStyles.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: _logo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
