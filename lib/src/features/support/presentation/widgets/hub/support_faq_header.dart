import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text_styles.dart';

/// "Frequently asked" heading of the hub's FAQ card.
class SupportFaqHeader extends StatelessWidget {
  const SupportFaqHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'support.frequently_asked'.tr(),
      style: AppTextStyles.headingMedium.copyWith(
        fontWeight: AppTextStyles.bold,
      ),
    );
  }
}
