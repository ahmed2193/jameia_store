import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_failure_view.dart';
import 'home_feed_view.dart';
import 'home_loading_view.dart';
import 'home_popup_queue.dart';

/// Switches the home tab on the cubit state — skeleton, feed (a saved copy
/// included), empty, and with nothing saved the failure under the real
/// header ("Checking your connection…", "No connection", or the error +
/// retry) — and runs the one-shot effects: the failed-refresh message told
/// the shared way (offline: only the banner), the marketing popup queue
/// (only while Home is the visible shell tab), and one silent refresh when
/// the connection returns.
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
        child: ScreenFailureListener<HomeCubit, HomeState>(
          child: BlocConsumer<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                current.hasPendingPopups && !previous.hasPendingPopups,
            listener: (context, state) => _showDuePopups(),
            // The popup latch and a transient refresh failure change nothing on
            // screen: never rebuild the whole feed for them.
            buildWhen: (previous, current) =>
                current.load.screenChangedFrom(previous.load) ||
                previous.feed != current.feed ||
                previous.bootstrap != current.bootstrap,
            builder: (context, state) => switch (state.status) {
              LoadPhase.initial ||
              LoadPhase.loading => HomeLoadingView(bootstrap: state.bootstrap),
              LoadPhase.error => HomeFailureView(
                bootstrap: state.bootstrap,
                failure: state.failure,
                onRetry: () => context.read<HomeCubit>().load(),
              ),
              LoadPhase.loaded when state.isEmpty => BrandedRefresh(
                onRefresh: () => context.read<HomeCubit>().refresh(),
                child: EmptyStateView(
                  message: 'home.empty'.tr(),
                  icon: Icons.storefront_outlined,
                  actionLabel: 'common.refresh'.tr(),
                  onAction: () => context.read<HomeCubit>().load(),
                ),
              ),
              LoadPhase.loaded => HomeFeedView(
                feed: state.feed,
                bootstrap: state.bootstrap,
              ),
            },
          ),
        ),
      ),
    );
  }
}
