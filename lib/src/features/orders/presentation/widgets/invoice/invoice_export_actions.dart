import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/hero_secondary_button.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../../../../core/widgets/inline_field_error.dart';
import '../../cubit/invoice_export_cubit.dart';
import '../../cubit/invoice_export_state.dart';
import 'invoice_share_button.dart';

/// What to do with the ready file: save it to the device (the system's
/// "Save to…" / "Save to Files" — no permission asked), share it, print it.
/// The buttons wait for the file, and take no tap while a system screen is
/// up (the save pill keeps its label). A failed action is told here, under
/// the buttons, where the eye already is.
class InvoiceExportActions extends StatelessWidget {
  const InvoiceExportActions({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvoiceExportCubit>();
    return BlocBuilder<InvoiceExportCubit, InvoiceExportState>(
      buildWhen: (previous, current) =>
          previous.canAct != current.canAct ||
          previous.running != current.running ||
          previous.failure != current.failure,
      builder: (context, state) {
        // A file that could not be made is told by the file card.
        final failure = state.hasFailed ? null : state.failure;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroSubmitButton(
              label: 'orders.invoice_pdf_save'.tr(),
              sticker: true,
              enabled: state.canAct,
              holding: state.running != null,
              onPressed: cubit.save,
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(child: InvoiceShareButton(enabled: state.canAct)),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: HeroSecondaryButton(
                    label: 'orders.invoice_pdf_print'.tr(),
                    icon: HeroIcons.printer,
                    expanded: true,
                    onPressed: state.canAct ? cubit.printDocument : null,
                  ),
                ),
              ],
            ),
            if (failure != null)
              InlineFieldError(
                message: failure.localizedMessage,
                centered: true,
              ),
          ],
        );
      },
    );
  }
}
