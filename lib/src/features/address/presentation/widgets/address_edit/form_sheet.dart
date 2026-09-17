import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/utils/jameia_geocode.dart';
import '../../../../../core/widgets/core_widgets.dart';
import 'additional_note_section.dart';
import 'address_details_section.dart';
import 'contact_section.dart';
import 'delivery_address_card.dart';
import 'delivery_instructions_section.dart';
import 'sheet_grabber.dart';
import 'tag_section.dart';

/// FORM sheet — the scrollable schema-driven address-details form.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.onEditLocation,
    required this.onSave,
    required this.errors,
    required this.altError,
    required this.onClearError,
    required this.onClearAltError,
  });

  final VoidCallback onEditLocation;
  final VoidCallback onSave;
  // Inline validation: field → i18n KEY (resolved with .tr() per field).
  final Map<AddrField, String> errors;
  final bool altError;
  final ValueChanged<AddrField> onClearError;
  final VoidCallback onClearAltError;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.s16),
        children: [
          const SheetGrabber(),
          // 1. Delivery address — resolved area + "Edit" → SELECT.
          DeliveryAddressCard(onEdit: onEditLocation),
          // 2. Address details — struct-type tabs + schema-driven inputs.
          AddressDetailsSection(errors: errors, onClearError: onClearError),
          // 3. Contact — name + phone (+965).
          ContactSection(errors: errors, onClearError: onClearError),
          // 4. Delivery instructions — hand-to-me vs leave-at-spot (+ alt + spots).
          DeliveryInstructionsSection(
            altError: altError,
            onClearAltError: onClearAltError,
          ),
          // 5. Additional note.
          const AdditionalNoteSection(),
          // 6. Tag / label — Home | Work | Hangout | Other.
          const TagSection(),
          // 7. Save CTA.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s12,
              AppSpacing.s8,
              AppSpacing.s12,
              AppSpacing.s12,
            ),
            // ALWAYS tappable in FORM so the user can tap Save to SEE what's
            // wrong (inline errors). Validation happens in onSave → _save().
            child: AppButton(
              label: 'addr.save_address'.tr(),
              onPressed: onSave,
              radius: AppRadius.r1,
            ),
          ),
        ],
      ),
    );
  }
}
