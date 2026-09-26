import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';

/// End of the orders list while the server has more: a loader while a page
/// is on its way, otherwise an underlined "Load more" link. Both sit in one
/// fixed-height box, so swapping them never moves the end of the list.
///
/// [autoLoad] is for a list that shows nothing yet — its rows may sit on a
/// later page, and with nothing to scroll the customer has no way to ask.
/// A list that already has rows pages on scroll (see `OrdersList`), never
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
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
      child: SizedBox(
        height: AppSize.s44,
        child: BlocSelector<OrdersCubit, OrdersState, bool>(
          selector: (state) => state.isLoadingMore,
          builder: (context, loading) => FadeThroughSwitcher(
            stateKey: loading,
            child: loading
                ? const AppLoader(size: AppSize.s20)
                : Center(
                    child: TextButton(
                      onPressed: () => context.read<OrdersCubit>().loadMore(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryText,
                        minimumSize: const Size(0, AppSize.s44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: AppTextStyles.label.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      child: Text('orders.load_more'.tr()),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
