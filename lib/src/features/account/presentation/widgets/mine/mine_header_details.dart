import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/auth_customer_entity.dart';
import 'mine_header_metrics.dart';
import 'mine_pro_badge.dart';
import 'mine_sign_in_pill.dart';

/// The centred text under the open header's avatar. Signed in: the name (or
/// "Complete your profile" while the account has none) with the PRO pill of
/// a member, then the phone number, laid out left-to-right in both
/// languages. A guest: the sign-in title, a two-line pitch and the sign-in
/// pill. [fade] (1 → 0 as the header collapses) scales the ink's alpha —
/// colours only, no opacity layer.
class MineHeaderDetails extends StatelessWidget {
  const MineHeaderDetails({super.key, required this.customer, this.fade = 1});

  final AuthCustomerEntity? customer;
  final double fade;

  static const double _badgeGap = AppSpacing.s6;

  /// What the header calls the customer — shared with the collapsed bar.
  static String titleFor(AuthCustomerEntity? customer, String languageCode) {
    if (customer == null) return 'profile.sign_in_title'.tr();
    if (customer.needsName) return 'profile.complete_profile'.tr();
    return customer.displayNameFor(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final person = customer;
    final title = titleFor(person, context.locale.languageCode);
    final titleStyle = AppTextStyles.headingLarge.copyWith(
      fontWeight: AppTextStyles.bold,
      color: AppColors.primaryText.withValues(alpha: fade),
    );
    final subtitleStyle = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.secondaryText.withValues(alpha: fade),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
            ),
            if (person?.isPro ?? false) ...[
              const SizedBox(width: _badgeGap),
              MineProBadge(opacity: fade),
            ],
          ],
        ),
        const SizedBox(height: MineHeaderMetrics.lineGap),
        if (person == null) ...[
          Text(
            'profile.sign_in_subtitle'.tr(),
            maxLines: MineHeaderMetrics.guestSubtitleLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: subtitleStyle,
          ),
          const SizedBox(height: MineHeaderMetrics.ctaGap),
          MineSignInPill(opacity: fade),
        ] else
          // Phone digits read left-to-right in Arabic too.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              person.phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
          ),
      ],
    );
  }
}
