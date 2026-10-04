import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/navigation/hero_snack_bar.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/hero_bottom_bar.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../../domain/entities/invoice_language.dart';
import '../cubit/invoice_export_cubit.dart';
import '../cubit/invoice_export_state.dart';
import '../cubit/invoice_preview_cubit.dart';
import '../widgets/invoice/invoice_export_actions.dart';
import '../widgets/invoice_pdf/invoice_pdf_side_layout.dart';
import '../widgets/invoice_pdf/invoice_pdf_stack_layout.dart';

/// The invoice as a PDF, seen before it leaves the phone
/// (`Routes.orderInvoicePdf`, `extra`: the order): the file is made in the
/// app's language the moment the page opens (the other language one tap
/// away), its pages show as the system's PDF renderer draws them, and only
/// then is it saved to the device, shared or printed. Made on the device,
/// so offline too. A save says "Invoice saved" and stays, for a share next.
class OrderInvoicePdfPage extends StatelessWidget {
  const OrderInvoicePdfPage({super.key, required this.order});

  final OrderEntity order;

  /// A new file (the other language) redraws the preview; none clears it.
  static void _preview(BuildContext context, InvoiceExportState state) =>
      context.read<InvoicePreviewCubit>().show(state.document);

  static void _saved(BuildContext context, InvoiceExportState _) =>
      showHeroSnackBar(
        context,
        'orders.invoice_pdf_saved'.tr(),
        tone: HeroSnackTone.success,
      );

  @override
  Widget build(BuildContext context) {
    final sideBySide = InvoicePdfSideLayout.fits(MediaQuery.sizeOf(context));
    final appLanguage = InvoiceLanguage.of(context.locale.languageCode);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<InvoiceExportCubit>()..prepare(order, appLanguage),
        ),
        BlocProvider(create: (_) => sl<InvoicePreviewCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<InvoiceExportCubit, InvoiceExportState>(
            listenWhen: (previous, current) =>
                previous.document != current.document,
            listener: _preview,
          ),
          BlocListener<InvoiceExportCubit, InvoiceExportState>(
            listenWhen: (previous, current) =>
                current.completed == InvoiceExportAction.save,
            listener: _saved,
          ),
        ],
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: HeroTitleBar(
            title: 'orders.invoice_pdf_sheet_title'.tr(),
            subtitle: 'orders.invoice_pdf_sheet_subtitle'.tr(
              namedArgs: {'number': Formatters.isolate(order.orderNumber)},
            ),
          ),
          bottomNavigationBar: sideBySide
              ? null
              : const HeroBottomBar(child: InvoiceExportActions()),
          body: sideBySide
              ? InvoicePdfSideLayout(orderNumber: order.orderNumber)
              : InvoicePdfStackLayout(orderNumber: order.orderNumber),
        ),
      ),
    );
  }
}
