import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/phone_number.dart';
import '../auth_link_button.dart';

/// The SMS badge, title, "we sent a code to" line and the number itself —
/// bold, left-to-right in either language — with the Edit link that goes
/// back to the phone step.
class OtpHeader extends StatelessWidget {
  const OtpHeader({super.key, required this.phone});

  final PhoneNumber phone;

  static const double _badge = AppSize.s48;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  void _editPhone(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox.square(
          dimension: _badge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandLightBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sms_outlined,
              size: AppSize.s24,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          'auth.otp_title'.tr(),
          style: AppTextStyles.displayMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(
          'auth.otp_sent_by_sms'.tr(),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        Wrap(
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
