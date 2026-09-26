import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/auth_customer_entity.dart';
import 'mine_header_details.dart';

/// The name beside the docked avatar in the collapsed bar. It fades in over
/// the end of the collapse through its ink alpha ([reveal] 0 → 1) and is
/// left out of the accessibility tree — the open header already says it.
class MineHeaderCompactTitle extends StatelessWidget {
  const MineHeaderCompactTitle({
    super.key,
    required this.customer,
    required this.reveal,
  });

  final AuthCustomerEntity? customer;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          MineHeaderDetails.titleFor(customer, context.locale.languageCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.primaryText.withValues(alpha: reveal),
          ),
        ),
      ),
    );
  }
}
