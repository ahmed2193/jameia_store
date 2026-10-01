import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/screen_load.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../../core/widgets/load_more_footer.dart';
import '../../../../../core/widgets/load_more_offline_note.dart';
import '../../cubit/product_listing_cubit.dart';
import '../../cubit/product_listing_state.dart';

/// Tail of a paginated grid: the shared [LoadMoreFooter] — dots while the
/// next page is coming, the retry pill when it failed — offline, "more will
/// load when you're back" instead (the list asks again by itself on
/// reconnect) — nothing otherwise. It selects the next page's progress
/// itself, so the grid above never rebuilds for it.
class ListingLoadMoreFooter extends StatelessWidget {
  const ListingLoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductListingCubit, ProductListingState, NextPageLoad>(
      selector: (state) => state.load.nextPage,
      builder: (context, nextPage) {
        final failed = nextPage == NextPageLoad.failed;
        if (failed && ConnectivityScope.isOfflineOf(context)) {
          return const LoadMoreOfflineNote();
        }
        if (nextPage == NextPageLoad.idle) return const SizedBox.shrink();
        return LoadMoreFooter(
          failed: failed,
          onRetry: () =>
              context.read<ProductListingCubit>().loadMore(retry: true),
        );
      },
    );
  }
}
