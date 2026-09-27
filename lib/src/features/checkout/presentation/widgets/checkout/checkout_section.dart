import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import 'checkout_section_title.dart';

/// One titled section of a checkout block: the heading, then [child] inset
/// by [padding] — the page's 12 dp gutter by default; an inset card passes
/// its own 8 dp, a row that bleeds to the edges passes zero. The rhythm
/// between sections is set here and in [CheckoutSectionTitle].
class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.s12,
    ),
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckoutSectionTitle(title),
        Padding(padding: padding, child: child),
      ],
    );
  }
}
