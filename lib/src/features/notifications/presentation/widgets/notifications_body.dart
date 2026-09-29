import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import 'notifications_empty_view.dart';
import 'notifications_list.dart';
import 'notifications_skeleton.dart';

/// Switches the inbox screen on the cubit status: the rows' bones on a first
/// load with nothing saved (cross-fading into the inbox); the saved inbox paints at
/// once (with the "Updated … ago" note while offline or after a failed
/// refresh); offline with nothing saved → "No connection". A returning
/// connection refreshes a saved or failed inbox. Transient flags (snack
/// bars) are the page listener's business, so they never rebuild this.
class NotificationsBody extends StatelessWidget {
  const NotificationsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<NotificationsCubit>().onReconnected(),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        buildWhen: (previous, current) =>
            current.load.screenChangedFrom(previous.load) ||
            previous.feed != current.feed,
        builder: (context, state) => FadeThroughSwitcher(
          // initial and loading share the bones; the sign-in prompt and the
          // error are two screens. Every swap is the same-place
          // cross-fade: the bones land as the inbox.
          stateKey: (
            state.status == LoadPhase.initial
                ? LoadPhase.loading
                : state.status,
            state.isSignedOut,
          ),
          crossFade: true,
          child: switch (state.status) {
            LoadPhase.initial ||
            LoadPhase.loading => const NotificationsSkeleton(),
            LoadPhase.error when state.isSignedOut => HeroStateView.signedOut(
              message: 'notifications.sign_in_prompt'.tr(),
            ),
            LoadPhase.error => FailureView(
              failure: state.failure,
              onRetry: () => context.read<NotificationsCubit>().load(),
            ),
            LoadPhase.loaded => Column(
              children: [
                const ScreenStaleNotice<
                  NotificationsCubit,
                  NotificationsState
                >(),
                Expanded(
                  child: state.feed.isEmpty
                      ? BrandedRefresh(
                          onRefresh: () =>
                              context.read<NotificationsCubit>().refresh(),
                          child: const CustomScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: NotificationsEmptyView(),
                              ),
                            ],
                          ),
                        )
                      : NotificationsList(feed: state.feed),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}
