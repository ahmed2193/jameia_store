import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/jameia_list_row.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_note_sheet.dart';
import 'checkout_sheet_frame.dart';

/// "Notes for the store" as a flat row: the note itself on one line under
/// the title (or a grey prompt), a chevron, and a tap that opens the note
/// sheet. The page has no text field; only this row rebuilds when the note
/// is saved.
class CheckoutNoteRow extends StatelessWidget {
  const CheckoutNoteRow({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.select<CheckoutCubit, String>(
      (cubit) => cubit.state.draft.notes,
    );
    return JameiaListRow(
      dense: true,
      icon: Icons.edit_note_rounded,
      title: 'checkout.notes_title'.tr(),
      subtitle: notes.trim().isEmpty ? 'checkout.notes_empty'.tr() : notes,
      subtitleMaxLines: 1,
      onTap: () => CheckoutSheetFrame.show<void>(
        context,
        // A sheet is its own route: pass the page's cubit on.
        checkout: context.read<CheckoutCubit>(),
        builder: (_) => const CheckoutNoteSheet(),
      ),
    );
  }
}
