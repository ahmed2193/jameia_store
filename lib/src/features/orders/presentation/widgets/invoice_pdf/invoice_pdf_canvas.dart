import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_state_view.dart';
import '../../cubit/invoice_export_cubit.dart';
import '../../cubit/invoice_preview_cubit.dart';
import '../../cubit/invoice_preview_state.dart';
import 'invoice_pdf_page_sheet.dart';

/// The PDF itself before it leaves the phone: its pages on a grey desk, one
/// under the other, drawn by the system's own PDF renderer — so what shows
/// is what gets saved, shared or printed. Pinch to zoom in on the small
/// print. While the file is made, a blank sheet with the dots; a file that
/// could not be made, or pages that could not be drawn, say so with a Retry.
class InvoicePdfCanvas extends StatelessWidget {
  const InvoicePdfCanvas({super.key});

  static const double _maxZoom = 4;

  /// A page on a tablet stays the size of a sheet held in the hand.
  static const double _maxPageWidth = AppSize.s520;

  @override
  Widget build(BuildContext context) {
    final fileFailed = context.select<InvoiceExportCubit, bool>(
      (cubit) => cubit.state.hasFailed,
    );
    return ColoredBox(
      color: AppColors.smallBackground,
      child: BlocBuilder<InvoicePreviewCubit, InvoicePreviewState>(
        builder: (context, preview) {
          if (fileFailed) {
            return HeroStateView.error(
              message: 'orders.invoice_pdf_failed'.tr(),
              onRetry: context.read<InvoiceExportCubit>().retry,
            );
          }
          if (preview.status == InvoicePreviewStatus.failed) {
            return HeroStateView.error(
              message: 'orders.invoice_pdf_preview_failed'.tr(),
              onRetry: context.read<InvoicePreviewCubit>().retry,
            );
          }
          // No file yet: one blank sheet with the dots while it is made.
          final pageCount = math.max(preview.pageCount, 1);
          return InteractiveViewer(
            maxScale: _maxZoom,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: pageCount,
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxPageWidth),
                  child: InvoicePdfPageSheet(
                    number: index + 1,
                    pageCount: pageCount,
                    image: index < preview.pages.length
                        ? preview.pages[index]
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
