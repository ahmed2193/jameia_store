import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/navigation/navigation.dart';
import 'login_other_methods_toggle.dart';
import 'login_social_button.dart';

/// The other ways in, under "or with": the Google pill, then "Other methods"
/// opening Apple and Facebook below it. The backend only offers phone sign-in
/// today, so each one says it is coming soon instead of faking a sign-in.
class LoginSocialSection extends StatefulWidget {
  const LoginSocialSection({super.key, required this.firstCascadeIndex});

  /// Entrance-cascade step of the Google pill (the section follows the
  /// phone unit, the CTA and the divider on the page).
  final int firstCascadeIndex;

  @override
  State<LoginSocialSection> createState() => _LoginSocialSectionState();
}

class _LoginSocialSectionState extends State<LoginSocialSection> {
  static const (String, String) _google = (HeroAssets.loginGoogle, 'Google');
  static const List<(String, String)> _others = [
    (HeroAssets.loginApple, 'Apple'),
    (HeroAssets.loginFacebook, 'Facebook'),
  ];

  bool _expanded = false;

  void _comingSoon() =>
      showHeroSnackBar(context, 'auth.social_coming_soon'.tr());

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final first = widget.firstCascadeIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntranceCascadeItem(
          index: first,
          child: LoginSocialButton(
            icon: _google.$1,
            label: _google.$2,
            onTap: _comingSoon,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        EntranceCascadeItem(
          index: first + 1,
          child: Center(
            child: LoginOtherMethodsToggle(expanded: _expanded, onTap: _toggle),
          ),
        ),
        CollapseReveal(
          visible: _expanded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (icon, provider) in _others) ...[
                const SizedBox(height: AppSpacing.s8),
                LoginSocialButton(
                  icon: icon,
                  label: 'auth.continue_with'.tr(
                    namedArgs: {'provider': provider},
                  ),
                  onTap: _comingSoon,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
