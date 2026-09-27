import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/phone_number.dart';
import '../auth_link_button.dart';

/// The code step's heading, centred like the phone step's "Welcome": the
/// title, "we sent a code by SMS to" and the number itself — bold, left to
/// right in either language — with the Edit link back to the phone step.
class OtpHeader extends StatelessWidget {
  const OtpHeader({super.key, required this.phone});

  final PhoneNumber phone;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  void _editPhone(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            'auth.otp_title'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'auth.otp_sent_by_sms'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.subheadingLarge.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.s12,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                phone.display,
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: AppTextStyles.bold,
                  fontFeatures: _tabular,
                ),
              ),
            ),
            AuthLinkButton(
              label: 'auth.otp_edit'.tr(),
              onPressed: () => _editPhone(context),
            ),
          ],
        ),
      ],
    );
  }
}
