import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';

/// A ticket's first line: the glyph — the offer kind's Hero plate
/// ([OfferPlate]: "%", voucher, scooter, gift) or, for a coupon code and any
/// other offer, the tilted amber ticket — and the value in big bold type
/// ("10% off", a coupon code), one line.
class CheckoutTicketHeadline extends StatelessWidget {
  const CheckoutTicketHeadline({
    super.key,
    required this.text,
    this.asset = HeroAssets.checkoutTicket,
  });

  final String text;

  /// A `HeroAssets` plate.
  final String asset;

  static const double iconSize = AppSize.s26;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroSvgGlyph.art(asset, size: iconSize),
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
