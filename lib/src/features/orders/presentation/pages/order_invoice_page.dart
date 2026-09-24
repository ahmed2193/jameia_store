import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/signed_out_view.dart';
import '../cubit/order_invoice_cubit.dart';
import '../cubit/order_invoice_state.dart';
import '../widgets/invoice/invoice_body.dart';

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
        backgroundColor: AppColors.mediumBackground,
        appBar: AppBar(
          title: Text('orders.invoice_title'.tr()),
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          elevation: 0,
        ),
        body: BlocBuilder<OrderInvoiceCubit, OrderInvoiceState>(
          builder: (context, state) {
            final order = state.order;
            switch (state.status) {
              case OrderInvoiceStatus.initial:
              case OrderInvoiceStatus.loading:
                return const AppLoader();
              case OrderInvoiceStatus.error:
                if (state.isSignedOut) {
                  return SignedOutView(message: 'orders.sign_in_required'.tr());
                }
                return ErrorView(
                  message: state.failure?.localizedMessage,
                  onRetry: () =>
                      context.read<OrderInvoiceCubit>().load(orderId),
                );
              case OrderInvoiceStatus.loaded:
                return order == null
                    ? const AppLoader()
                    : InvoiceBody(order: order);
            }
          },
        ),
      ),
    );
  }
}
