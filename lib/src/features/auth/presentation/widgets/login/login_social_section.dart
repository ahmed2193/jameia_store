import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/navigation/navigation.dart';
import 'login_social_button.dart';

/// Google / Apple / Facebook buttons. The backend only offers OTP login today,
/// so these announce "coming soon" instead of faking a sign-in.
class LoginSocialSection extends StatelessWidget {
  const LoginSocialSection({super.key, required this.firstStaggerIndex});

  /// Entrance-stagger index of the first button (the section follows the
  /// heading / field / CTA / divider on the page).
  final int firstStaggerIndex;

  static const List<(String icon, String provider)> _providers = [
    (JameiaAssets.loginGoogle, 'Google'),
    (JameiaAssets.loginApple, 'Apple'),
    (JameiaAssets.loginFacebook, 'Facebook'),
  ];

  void _comingSoon(BuildContext context) =>
      showJameiaSnackBar(context, 'auth.social_coming_soon'.tr());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _providers.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s12),
          StaggerEntrance(
            index: firstStaggerIndex + i,
            child: LoginSocialButton(
              icon: _providers[i].$1,
              label: 'auth.continue_with'.tr(
                namedArgs: {'provider': _providers[i].$2},
              ),
              onTap: () => _comingSoon(context),
            ),
          ),
        ],
      ],
    );
  }
}
