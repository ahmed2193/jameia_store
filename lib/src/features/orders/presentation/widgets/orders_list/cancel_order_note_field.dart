import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/jameia_input_decoration.dart';
import '../../../domain/entities/cancel_order_request.dart';

/// The optional note of a cancel request, capped at the length the API
/// takes. The sheet owns [controller] and reads it when the customer
/// confirms.
class CancelOrderNoteField extends StatelessWidget {
  const CancelOrderNoteField({super.key, required this.controller});

  final TextEditingController controller;

  static const int _noteLines = 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: TextField(
        controller: controller,
        maxLength: CancelOrderRequest.maxNoteLength,
        maxLines: _noteLines,
        style: AppTextStyles.itemTitle,
        cursorColor: AppColors.primaryText,
        decoration: JameiaInputDecoration.outlined(
          hintText: 'orders.cancel_note_hint'.tr(),
        ),
      ),
    );
  }
}
