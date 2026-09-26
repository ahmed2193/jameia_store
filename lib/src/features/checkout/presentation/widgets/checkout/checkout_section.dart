import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import 'checkout_section_title.dart';

/// One titled block of the checkout page: the group heading, then [child]
/// inset by the page gutter. Every section but the items (a sliver with its
/// own heading) sits in one of these, so the rhythm is set in one place.
class CheckoutSection extends StatelessWidget {
  const CheckoutSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckoutSectionTitle(title),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: child,
        ),
      ],
    );
  }
}
