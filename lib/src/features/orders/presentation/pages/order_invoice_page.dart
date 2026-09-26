import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/jameia_title_bar.dart';
import '../cubit/order_invoice_cubit.dart';
import '../cubit/order_invoice_state.dart';
import '../widgets/invoice/invoice_body.dart';
import '../widgets/order_detail_state_switcher.dart';

/// The order's invoice (`Routes.orderInvoice`, `extra`: order id): the
/// server's own totals, never recomputed on the device.
class OrderInvoicePage extends StatelessWidget {
  const OrderInvoicePage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderInvoiceCubit>()..load(orderId),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: JameiaTitleBar(title: 'orders.invoice_title'.tr()),
        body: ContentClamp(
          child: BlocBuilder<OrderInvoiceCubit, OrderInvoiceState>(
            builder: (context, state) {
              final order = state.order;
              return OrderDetailStateSwitcher(
                content:
                    state.status == OrderInvoiceStatus.loaded && order != null
                    ? InvoiceBody(order: order)
                    : null,
                failed: state.status == OrderInvoiceStatus.error,
                isSignedOut: state.isSignedOut,
                errorMessage: state.failure?.localizedMessage,
                onRetry: () => context.read<OrderInvoiceCubit>().load(orderId),
              );
            },
          ),
        ),
      ),
    );
  }
}
