import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Title above a checkout section, Hero-style: 18 sp bold in the 12 dp
/// gutter, 20 dp above and 12 dp below.
class CheckoutSectionTitle extends StatelessWidget {
  const CheckoutSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s20,
        AppSpacing.s12,
        AppSpacing.s12,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTextStyles.groupTitle),
      ),
    );
  }
}
