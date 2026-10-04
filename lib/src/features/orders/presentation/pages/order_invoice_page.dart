import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/navigation/sign_in_flow.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../cubit/order_invoice_cubit.dart';
import '../cubit/order_invoice_state.dart';
import '../widgets/invoice/invoice_body.dart';
import '../widgets/invoice/invoice_export_bar.dart';
import '../widgets/order_detail_state_switcher.dart';

/// The order's invoice (`Routes.orderInvoice`, `extra`: order id): the
/// server's own totals, never recomputed on the device. The copy saved on
/// the device shows at once (offline too, under the "Updated … ago" note);
/// offline with nothing saved → "No connection". A returning connection
/// refreshes a saved or failed invoice. Once it shows, "Download invoice"
/// opens it as a PDF (`Routes.orderInvoicePdf`): previewed in English or
/// Arabic, then saved, shared or printed — made on the device, so offline
/// too.
class OrderInvoicePage extends StatelessWidget {
  const OrderInvoicePage({super.key, required this.orderId});

  final String orderId;

  static void _signIn(BuildContext context) => SignInFlow.open(context);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderInvoiceCubit>()..load(orderId),
      // A refresh that failed under a saved invoice is told (offline, the
      // banner speaks instead); signed out → sign in.
      child: ScreenFailureListener<OrderInvoiceCubit, OrderInvoiceState>(
        onUnauthorized: _signIn,
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: HeroTitleBar(title: 'orders.invoice_title'.tr()),
          bottomNavigationBar: const InvoiceExportBar(),
          body: ContentClamp(
            maxWidth: InvoiceBody.maxWidth,
            // Below the provider: the page's own context is above it.
            child: Builder(
              builder: (context) => ReconnectRefresh(
                onReconnected: () =>
                    context.read<OrderInvoiceCubit>().onReconnected(),
                child: BlocBuilder<OrderInvoiceCubit, OrderInvoiceState>(
                  buildWhen: (previous, current) =>
                      current.load.screenChangedFrom(previous.load) ||
                      previous.order != current.order,
                  builder: (context, state) {
                    final order = state.order;
                    return OrderDetailStateSwitcher(
                      content: state.isLoaded && order != null
                          ? Column(
                              children: [
                                // Folds by itself (CollapseReveal, fast).
                                const ScreenStaleNotice<
                                  OrderInvoiceCubit,
                                  OrderInvoiceState
                                >(),
                                Expanded(child: InvoiceBody(order: order)),
                              ],
                            )
                          : null,
                      failure: state.loadFailure,
                      isSignedOut: state.isSignedOut,
                      onRetry: () =>
                          context.read<OrderInvoiceCubit>().load(orderId),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
