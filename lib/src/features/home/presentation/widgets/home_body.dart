import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_feed_view.dart';
import 'home_loading_view.dart';
import 'home_offline_view.dart';
import 'home_popup_queue.dart';

/// Switches the home tab on the cubit state — skeleton, feed (a saved copy
/// included), empty, "no connection" (nothing saved, offline), error + retry —
/// and runs the one-shot effects: the failed-refresh message (never while
/// offline: the banner speaks), the marketing popup queue (only while Home
/// is the visible shell tab), and one silent refresh when the connection
/// returns.
class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  static const Key _visibilityKey = Key('home-tab-visibility');
  static const double _visibleFraction = 0.5;

  /// The shell's `IndexedStack` builds every tab up-front, so "mounted" does
  /// not mean "on screen".
  bool _isVisible = false;

  void _showDuePopups() {
    final cubit = context.read<HomeCubit>();
    if (!_isVisible || !cubit.state.hasPendingPopups) return;
    final due = cubit.state.duePopups;
    cubit.markPopupsShown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) HomePopupQueue.show(context, due);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<HomeCubit>().onReconnected(),
      child: VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: (info) {
          _isVisible = info.visibleFraction > _visibleFraction;
          if (mounted) _showDuePopups();
        },
        child: BlocConsumer<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              (current.failure != null &&
                  current.isLoaded &&
                  previous.failure != current.failure) ||
              (current.hasPendingPopups && !previous.hasPendingPopups),
          listener: (context, state) {
            final failure = state.failure;
            if (failure != null && state.isLoaded) {
              showFailureSnackBar(context, failure);
            }
            _showDuePopups();
          },
          // The popup latch and a transient refresh failure change nothing on
          // screen: never rebuild the whole feed for them.
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.feed != current.feed ||
              previous.bootstrap != current.bootstrap,
          builder: (context, state) => switch (state.status) {
            HomeStatus.initial ||
            HomeStatus.loading => HomeLoadingView(bootstrap: state.bootstrap),
            HomeStatus.error when state.failure is NetworkFailure =>
              HomeOfflineView(
                bootstrap: state.bootstrap,
                onRetry: () => context.read<HomeCubit>().load(),
              ),
            HomeStatus.error => ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: () => context.read<HomeCubit>().load(),
            ),
            HomeStatus.loaded when state.isEmpty => BrandedRefresh(
              onRefresh: () => context.read<HomeCubit>().refresh(),
              child: EmptyStateView(
                message: 'home.empty'.tr(),
                icon: Icons.storefront_outlined,
                actionLabel: 'common.refresh'.tr(),
                onAction: () => context.read<HomeCubit>().load(),
              ),
            ),
            HomeStatus.loaded => HomeFeedView(
              feed: state.feed,
              bootstrap: state.bootstrap,
            ),
          },
        ),
      ),
    );
  }
}
