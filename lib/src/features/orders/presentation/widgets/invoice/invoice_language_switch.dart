import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/hero_segmented_control.dart';
import '../../../domain/entities/invoice_language.dart';
import '../../cubit/invoice_export_cubit.dart';

/// The file's language: English | العربية, each name in its own language as
/// language pickers write them (read out under "Invoice language"). A switch
/// makes (or reuses) that file and the preview redraws; it is locked while a
/// system screen is up.
class InvoiceLanguageSwitch extends StatelessWidget {
  const InvoiceLanguageSwitch({super.key});

  static String _nameOf(InvoiceLanguage language) => switch (language) {
    InvoiceLanguage.english => 'orders.invoice_pdf_language_en'.tr(),
    InvoiceLanguage.arabic => 'orders.invoice_pdf_language_ar'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final (language, locked) = context
        .select<InvoiceExportCubit, (InvoiceLanguage, bool)>(
          (cubit) => (cubit.state.language, cubit.state.running != null),
        );
    return Semantics(
      container: true,
      label: 'orders.invoice_pdf_language'.tr(),
      child: HeroSegmentedControl<InvoiceLanguage>(
        values: InvoiceLanguage.values,
        selected: language,
        labelOf: _nameOf,
        tone: HeroSegmentTone.brandSoft,
        onChanged: locked
            ? null
            : context.read<InvoiceExportCubit>().chooseLanguage,
      ),
    );
  }
}
