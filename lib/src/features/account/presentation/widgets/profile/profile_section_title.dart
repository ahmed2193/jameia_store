import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text_styles.dart';

/// Bold heading at the top of a profile section card.
class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: AppTextStyles.headingLarge.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
