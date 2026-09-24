import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import 'address_details_section.dart';
import 'address_save_button.dart';
import 'default_address_switch.dart';
import 'delivery_address_card.dart';
import 'form_sheet_header.dart';
import 'keyboard_inset_padding.dart';
import 'notes_section.dart';
import 'phone_section.dart';
import 'tag_section.dart';

/// FORM sheet — full height: a pinned header over the scrollable address form
/// (one section per API concern). The list stops above the keyboard, so a
/// focused field can always scroll into view.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.isEdit,
    required this.onEditLocation,
  });

  final bool isEdit;

  /// Back to the map to move the pin.
  final VoidCallback onEditLocation;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: Column(
        children: [
          FormSheetHeader(isEdit: isEdit, onClose: onEditLocation),
          Expanded(
            child: KeyboardInsetPadding(
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.s16),
                children: [
                  // Pinned area + "Edit" → back to the map.
                  DeliveryAddressCard(onEdit: onEditLocation),
                  const AddressDetailsSection(),
                  const PhoneSection(),
                  const NotesSection(),
                  const TagSection(),
                  const DefaultAddressSwitch(),
                  const AddressSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
