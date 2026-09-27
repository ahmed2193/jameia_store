import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_input_decoration.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_sheet_frame.dart';

/// The note for the store, in the checkout sheet shell: one field (the
/// API's 256 characters, with a counter) seeded from the draft, and a
/// sticker "Save".
///
/// Typing only edits the field; the draft changes once, when the sheet
/// closes. "Save" commits and closes; any other way out (swipe down, the
/// ✕, the scrim, back) commits the changed text too, so a note is never
/// lost to how the sheet was closed. Open it with
/// `CheckoutSheetFrame.show(checkout: …)` — it reads the page's cubit.
class CheckoutNoteSheet extends StatefulWidget {
  const CheckoutNoteSheet({super.key});

  @override
  State<CheckoutNoteSheet> createState() => _CheckoutNoteSheetState();
}

class _CheckoutNoteSheetState extends State<CheckoutNoteSheet> {
  static const int _lines = 4;

  late final CheckoutCubit _checkout;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _checkout = context.read<CheckoutCubit>();
    _controller = TextEditingController(text: _checkout.state.draft.notes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final notes = _controller.text;
    if (notes != _checkout.state.draft.notes) _checkout.setNotes(notes);
  }

  void _save() {
    _commit();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _commit();
      },
      child: CheckoutSheetFrame(
        title: 'checkout.notes_title'.tr(),
        footer: HeroSubmitButton(
          label: 'checkout.note_save'.tr(),
          sticker: true,
          height: AppSize.s48,
          onPressed: _save,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s12,
            0,
            AppSpacing.s12,
            AppSpacing.s12,
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: CheckoutDraft.maxNotesLength,
            maxLines: _lines,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.itemTitle,
            cursorColor: AppColors.primaryText,
            decoration: HeroInputDecoration.outlined(
              hintText: 'checkout.notes_hint'.tr(),
            ),
          ),
        ),
      ),
    );
  }
}
