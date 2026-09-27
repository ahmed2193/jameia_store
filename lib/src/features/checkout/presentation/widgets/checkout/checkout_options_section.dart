import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'checkout_note_row.dart';
import 'checkout_section.dart';

/// "Additional options": the note for the store (`POST /v1/orders` →
/// `notes`). Hero's "If out of stock" choice is not built — the API has no
/// field for it, and the note belongs to the customer's own words.
class CheckoutOptionsSection extends StatelessWidget {
  const CheckoutOptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckoutSection(
      title: 'checkout.options_title'.tr(),
      padding: EdgeInsetsDirectional.zero,
      child: const CheckoutNoteRow(),
    );
  }
}
