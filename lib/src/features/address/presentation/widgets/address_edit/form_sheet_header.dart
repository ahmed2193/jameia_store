import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import 'circle_button.dart';
import 'sheet_grabber.dart';

/// Pinned top of the full-height FORM sheet: grabber, the close button (back
/// to the map pin) and the screen title.
class FormSheetHeader extends StatelessWidget {
  const FormSheetHeader({
    super.key,
    required this.isEdit,
    required this.onClose,
  });

  final bool isEdit;
  final VoidCallback onClose;

  /// Keeps the title centred against the close button on the other side.
  static const double _closeButtonSize = AppSize.s40;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetGrabber(),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.s12,
            end: AppSpacing.s12,
            bottom: AppSpacing.s8,
          ),
          child: Row(
            children: [
              CircleButton(icon: JameiaIcons.close, onTap: onClose),
              Expanded(
                child: Text(
                  (isEdit ? 'addr.edit_address' : 'addr.new_address').tr(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingLarge.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              const SizedBox(width: _closeButtonSize),
            ],
          ),
        ),
      ],
    );
  }
}
