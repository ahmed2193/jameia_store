import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/hero_title_bar.dart';
import '../../../../../core/widgets/keyboard_inset_padding.dart';
import '../../../../../core/widgets/round_back_button.dart';
import 'address_details_section.dart';
import 'address_pin_preview.dart';
import 'address_place_header.dart';
import 'address_save_bar.dart';
import 'default_address_switch.dart';
import 'notes_section.dart';
import 'phone_section.dart';
import 'tag_section.dart';

/// The address form over the map picker: the place and its type, the
/// address fields that type needs and the contact number (every required
/// field first), directions, the pin on the map ("Adjust pin" goes back to
/// the map), the label and the default switch — with Save pinned at the foot, riding on the keyboard.
/// Only the Save bar follows the keyboard frame by frame; the list above it
/// just gets shorter.
class AddressDetailsStage extends StatelessWidget {
  const AddressDetailsStage({
    super.key,
    required this.isEdit,
    required this.snapshot,
    required this.onBack,
    required this.onAdjustPin,
    required this.onChangeType,
  });

  final bool isEdit;

  /// The map at the confirmed pin.
  final ValueListenable<Uint8List?> snapshot;
  final VoidCallback onBack;
  final VoidCallback onAdjustPin;
  final VoidCallback onChangeType;

  static const double _sectionGap = AppSpacing.s24;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: Column(
        children: [
          HeroTitleBar(
            title: (isEdit ? 'addr.edit_address' : 'addr.new_address').tr(),
            leading: RoundBackButton(onPressed: onBack),
          ),
          Expanded(
            // The keyboard's Next walks the form as one unit: read in
            // reading order with the Save bar, a field half under the bar
            // shares its band and Next jumped to Save.
            child: FocusTraversalGroup(
              // A readable column on a tablet.
              child: ContentClamp(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.gutter,
                    AppSpacing.s20,
                    AppSpacing.gutter,
                    AppSpacing.s24,
                  ),
                  children: [
                    AddressPlaceHeader(onChangeType: onChangeType),
                    const SizedBox(height: _sectionGap),
                    const AddressDetailsSection(),
                    const SizedBox(height: _sectionGap),
                    const PhoneSection(),
                    const SizedBox(height: _sectionGap),
                    const NotesSection(),
                    const SizedBox(height: _sectionGap),
                    AddressPinPreview(
                      snapshot: snapshot,
                      onAdjust: onAdjustPin,
                    ),
                    const SizedBox(height: _sectionGap),
                    const TagSection(),
                    const SizedBox(height: AppSpacing.s12),
                    const DefaultAddressSwitch(),
                  ],
                ),
              ),
            ),
          ),
          const KeyboardInsetPadding(child: AddressSaveBar()),
        ],
      ),
    );
  }
}
