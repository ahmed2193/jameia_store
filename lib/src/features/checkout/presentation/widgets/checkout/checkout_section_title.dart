import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/jameia_section_header.dart';

/// Title above a checkout section: the flow's bold group heading in the page
/// gutter, 24 dp above and 8 dp below (docs/design_system.md).
class CheckoutSectionTitle extends StatelessWidget {
  const CheckoutSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return JameiaSectionHeader(
      title: text,
      titleStyle: AppTextStyles.groupTitle,
    );
  }
}
