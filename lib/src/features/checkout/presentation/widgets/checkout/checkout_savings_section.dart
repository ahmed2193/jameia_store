import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../../../config/theme/app_spacing.dart';
import 'checkout_savings_card.dart';
import 'checkout_section.dart';

/// "Instant savings": the cream card with the coupons-and-offers row (and
/// the tag of the nearest reward still to unlock) and, for a customer who
/// can redeem, the points row. The card is inset 8 dp, like Keeta's.
class CheckoutSavingsSection extends StatelessWidget {
  const CheckoutSavingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckoutSection(
      title: 'checkout.savings_title'.tr(),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s8),
      child: const CheckoutSavingsCard(),
    );
  }
}
