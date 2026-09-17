import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';

/// Terms-of-service / privacy-policy fine print with tappable links.
class LoginTermsText extends StatefulWidget {
  const LoginTermsText({super.key});

  @override
  State<LoginTermsText> createState() => _LoginTermsTextState();
}

class _LoginTermsTextState extends State<LoginTermsText> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()
      ..onTap = () => _open('auth.terms_of_service'.tr());
    _privacy = TapGestureRecognizer()
      ..onTap = () => _open('auth.privacy_policy'.tr());
  }

  void _open(String label) {
    if (!mounted) return;
    showJameiaSnackBar(
      context,
      'auth.opening_x'.tr(namedArgs: {'label': label}),
    );
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
      color: AppColors.tertiaryText,
      height: AppSize.lh1_4,
    );
    final link = base.copyWith(
      color: AppColors.link,
      fontWeight: AppTextStyles.medium,
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
