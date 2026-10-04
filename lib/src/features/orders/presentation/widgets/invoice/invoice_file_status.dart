import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../domain/entities/invoice_document.dart';
import '../../cubit/invoice_export_state.dart';

/// The line under the file's name: "Preparing your invoice…" with the dots,
/// "2 pages · 84 KB" once ready, or "Couldn't create the PDF" (the preview
/// beside it offers the Retry).
class InvoiceFileStatus extends StatelessWidget {
  const InvoiceFileStatus({
    super.key,
    required this.status,
    required this.document,
  });

  static const int _bytesPerKilobyte = 1024;

  final InvoiceExportStatus status;
  final InvoiceDocument? document;

  @override
  Widget build(BuildContext context) {
    final file = document;
    if (status == InvoiceExportStatus.failed) {
      return Text(
        'orders.invoice_pdf_failed'.tr(),
        style: AppTextStyles.meta.copyWith(color: AppColors.errorDeep),
      );
    }
    if (status != InvoiceExportStatus.ready || file == null) {
      return Row(
        children: [
          const AppLoader.inline(size: AppSize.s16),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              'orders.invoice_pdf_preparing'.tr(),
              style: AppTextStyles.meta,
            ),
          ),
        ],
      );
    }
    final kilobytes = (file.sizeInBytes / _bytesPerKilobyte).ceil();
    return Text(
      [
        'orders.invoice_pdf_pages'.plural(file.pageCount),
        // One unit in either direction: "84 KB", never "KB 84".
        Formatters.isolate(
          'orders.invoice_pdf_size'.tr(namedArgs: {'size': '$kilobytes'}),
        ),
      ].join(Formatters.middot),
      style: AppTextStyles.meta,
    );
  }
}
