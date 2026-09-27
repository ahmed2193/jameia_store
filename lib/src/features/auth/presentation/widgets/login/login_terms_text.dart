import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// The fine print at the foot of the sign-in sheet: continuing accepts the
/// store's Terms & Conditions and Privacy Policy, both underlined links that
/// open the store's own pages (`GET /v1/pages/{slug}`, pushed so "back"
/// returns to sign-in with the number still typed).
class LoginTermsText extends StatefulWidget {
  const LoginTermsText({super.key});

  @override
  State<LoginTermsText> createState() => _LoginTermsTextState();
}

class _LoginTermsTextState extends State<LoginTermsText> {
  /// CMS page slugs.
  static const String _termsSlug = 'terms';
  static const String _privacySlug = 'privacy';

  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => _open(_termsSlug);
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => _open(_privacySlug);

  void _open(String slug) {
    if (!mounted) return;
    context.push(Routes.contentPage, extra: slug);
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
      height: AppSize.lh1_4,
    );
    final link = base.copyWith(
      color: AppColors.primaryText,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primaryText,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: 'auth.terms_prefix'.tr()),
          TextSpan(
            text: 'auth.terms_of_service'.tr(),
            style: link,
            recognizer: _terms,
          ),
          TextSpan(text: 'auth.and_conjunction'.tr()),
          TextSpan(
            text: 'auth.privacy_policy'.tr(),
            style: link,
            recognizer: _privacy,
          ),
          TextSpan(text: 'auth.sentence_end'.tr()),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
