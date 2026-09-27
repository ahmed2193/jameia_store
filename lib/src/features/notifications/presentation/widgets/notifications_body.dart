import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import 'notifications_empty_view.dart';
import 'notifications_list.dart';

/// Switches the inbox screen on the cubit status: the saved inbox paints at
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
        builder: (context, state) => switch (state.status) {
          LoadPhase.initial || LoadPhase.loading => const AppLoader(),
          LoadPhase.error when state.isSignedOut => EmptyStateView(
            message: 'notifications.sign_in_prompt'.tr(),
            icon: Icons.lock_outline_rounded,
            actionLabel: 'auth.log_in_or_sign_up'.tr(),
            onAction: () => context.go(Routes.login),
          ),
          LoadPhase.error => FailureView(
            failure: state.failure,
            onRetry: () => context.read<NotificationsCubit>().load(),
          ),
          LoadPhase.loaded => Column(
            children: [
              const ScreenStaleNotice<NotificationsCubit, NotificationsState>(),
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
    );
  }
}
