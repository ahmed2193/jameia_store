import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';

import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../cubit/order_invoice_cubit.dart';
import '../../cubit/order_invoice_state.dart';
import 'invoice_body.dart';

/// "Download invoice" pinned under the invoice once it shows: opens the PDF
/// (`Routes.orderInvoicePdf`) to preview, then save, share or print. Nothing
/// while the invoice loads or failed — there is nothing to put in a file yet.
class InvoiceExportBar extends StatelessWidget {
  const InvoiceExportBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrderInvoiceCubit, OrderInvoiceState, OrderEntity?>(
      selector: (state) => state.isLoaded ? state.order : null,
      builder: (context, order) => SizeFadeSwitcher(
        stateKey: order != null,
        alignment: AlignmentDirectional.bottomCenter,
        child: order == null
            ? const SizedBox.shrink()
            : HeroBottomBar(
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: InvoiceBody.maxWidth,
                    ),
                    child: HeroSubmitButton(
                      label: 'orders.invoice_pdf_download'.tr(),
                      sticker: true,
                      onPressed: () =>
                          context.push(Routes.orderInvoicePdf, extra: order),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
