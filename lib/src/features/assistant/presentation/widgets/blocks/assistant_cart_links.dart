import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import 'assistant_card_link.dart';

/// The next step after the cart changed: look at the cart, or — when
/// nothing stands in the way — go straight to checkout.
class AssistantCartLinks extends StatelessWidget {
  const AssistantCartLinks({super.key, this.canCheckout = true});

  /// `false` while the cart is still under the minimum order.
  final bool canCheckout;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.s8,
      children: [
        AssistantCardLink(
          label: 'assistant.view_cart'.tr(),
          onTap: () => context.push(Routes.cartPreview),
        ),
        if (canCheckout)
          AssistantCardLink(
            label: 'assistant.checkout'.tr(),
            onTap: () => context.push(Routes.checkout),
          ),
      ],
    );
  }
}
