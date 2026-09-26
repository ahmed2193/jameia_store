import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/dot_sep.dart';
import 'pro_underlined_link.dart';

/// "Cancel anytime · Benefits apply instantly · Terms apply" above the CTA;
/// [termsOnly] keeps just the terms link (a member has nothing to join).
class ProTrustLine extends StatelessWidget {
  const ProTrustLine({super.key, this.termsOnly = false});

  /// CMS page with the membership terms.
  static const String _termsSlug = 'terms';

  final bool termsOnly;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!termsOnly) ...[
          Text('pro.cancel_anytime'.tr(), style: style),
          const DotSep(),
          Text('pro.instant_benefits'.tr(), style: style),
          const DotSep(),
        ],
        ProUnderlinedLink(
          label: 'pro.terms_apply'.tr(),
          style: AppTextStyles.captionLarge,
          onTap: () => context.push(Routes.contentPage, extra: _termsSlug),
        ),
      ],
    );
  }
}
