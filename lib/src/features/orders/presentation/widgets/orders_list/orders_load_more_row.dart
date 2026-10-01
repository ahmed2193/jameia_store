import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../../core/widgets/hero_text_link.dart';
import '../../../../../core/widgets/load_more_offline_note.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';

/// End of the orders list while the server has more: a loader while a page
/// is on its way, otherwise the underlined "Load more" [HeroTextLink]. Both
/// sit in one
/// fixed-height box, so swapping them never moves the end of the list. A
/// page that failed offline says "More will load when you're back" instead:
/// the list asks again by itself when the connection returns.
///
/// [autoLoad] is for a list that shows nothing yet — its rows may sit on a
/// later page, and with nothing to scroll the customer has no way to ask.
/// A list that already has rows pages on scroll (see `OrdersList`), never
/// from a build pass.
class OrdersLoadMoreRow extends StatefulWidget {
  const OrdersLoadMoreRow({super.key, this.autoLoad = false});

  final bool autoLoad;

  /// The list already keeps the side gutters.
  static const EdgeInsetsGeometry _offlinePadding =
      EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s12);

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
    return BlocSelector<OrdersCubit, OrdersState, (bool, bool)>(
      selector: (state) => (state.isLoadingMore, state.loadMoreFailed),
      builder: (context, paging) {
        final (loading, failed) = paging;
        if (failed && ConnectivityScope.isOfflineOf(context)) {
          return const LoadMoreOfflineNote(
            padding: OrdersLoadMoreRow._offlinePadding,
          );
        }
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s8,
          ),
          child: SizedBox(
            height: AppSize.s44,
            child: FadeThroughSwitcher(
              stateKey: loading,
              child: loading
                  ? const AppLoader.inline()
                  : Center(
                      child: HeroTextLink(
                        label: 'orders.load_more'.tr(),
                        navigates: false,
                        // An explicit ask: also after a failed page.
                        onTap: () =>
                            context.read<OrdersCubit>().loadMore(retry: true),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
