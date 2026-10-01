import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/hero_sheet_header.dart';

/// Pinned top of the full-height FORM sheet: the shared sheet header (the
/// handle, the screen title and the ✕ that goes back to the map pin).
class FormSheetHeader extends StatelessWidget {
  const FormSheetHeader({
    super.key,
    required this.isEdit,
    required this.onClose,
  });

  final bool isEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return HeroSheetHeader(
      title: (isEdit ? 'addr.edit_address' : 'addr.new_address').tr(),
      onClose: onClose,
    );
  }
}
