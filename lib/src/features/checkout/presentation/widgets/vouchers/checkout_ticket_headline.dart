import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/responsive/app_size.dart';

/// A ticket's first line: the tilted amber ticket glyph and the value in
/// big bold type ("10% off", a coupon code), one line.
class CheckoutTicketHeadline extends StatelessWidget {
  const CheckoutTicketHeadline({super.key, required this.text});

  final String text;

  static const double iconSize = AppSize.s26;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          JameiaAssets.checkoutTicket,
          width: iconSize,
          height: iconSize,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
