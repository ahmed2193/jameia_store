import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';

/// End of a tab while the server has more orders: a loader while a page is
/// on its way, otherwise the way to ask for the next one.
///
/// [autoLoad] is for a tab that shows nothing yet — its rows may sit on a
/// later page, and with nothing to scroll the customer has no way to ask.
/// A tab that already has rows pages on scroll (see `OrdersList`), never
/// from a build pass.
class OrdersLoadMoreRow extends StatefulWidget {
  const OrdersLoadMoreRow({super.key, this.autoLoad = false});

  final bool autoLoad;

  @override
  State<OrdersLoadMoreRow> createState() => _OrdersLoadMoreRowState();
}

class _OrdersLoadMoreRowState extends State<OrdersLoadMoreRow> {
  @override
  void initState() {
    super.initState();
    if (!widget.autoLoad) return;
    // After the frame: emitting during build would rebuild the list mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersCubit>().loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: BlocSelector<OrdersCubit, OrdersState, bool>(
        selector: (state) => state.isLoadingMore,
        builder: (context, loading) => loading
            ? const AppLoader(size: AppSize.s20)
            : Center(
                child: TextButton(
                  onPressed: () => context.read<OrdersCubit>().loadMore(),
                  child: Text('orders.load_more'.tr()),
                ),
              ),
      ),
    );
  }
}
