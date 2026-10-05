import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'phone_field.dart';
import 'section_header.dart';

/// Contact: the number the courier calls.
class PhoneSection extends StatelessWidget {
  const PhoneSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'addr.contact'.tr()),
        const PhoneField(),
      ],
    );
  }
}
