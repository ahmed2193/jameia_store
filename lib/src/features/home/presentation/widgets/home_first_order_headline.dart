import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import 'home_free_delivery_chip.dart';

/// The first-order bar's line: "[Free delivery] on your first order" — the
/// offer picked out in its chip, the rest in bold white — always on ONE
/// line, like the reference bar: a narrow phone, a long language or a large
/// text size scales the whole line down rather than wrapping it. A [Row],
/// not an inline span, so the chip, the gap and the words keep their order
/// and spacing in both directions (Arabic reads chip first, on the right).
class HomeFirstOrderHeadline extends StatelessWidget {
  const HomeFirstOrderHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.headingMedium.copyWith(
      color: AppColors.white,
      fontWeight: AppTextStyles.bold,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeFreeDeliveryChip(
            label: 'home.first_order_free'.tr(),
            style: style,
          ),
          const SizedBox(width: AppSpacing.s6),
          Text('home.first_order_rest'.tr(), maxLines: 1, style: style),
        ],
      ),
    );
  }
}
