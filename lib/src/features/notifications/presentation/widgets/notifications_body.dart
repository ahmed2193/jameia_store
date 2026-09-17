import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import 'notifications_empty_view.dart';
import 'notifications_list.dart';

/// Switches the inbox screen on the cubit status. Transient flags (snack
/// bars) are the page listener's business, so they never rebuild this.
class NotificationsBody extends StatelessWidget {
  const NotificationsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.feed != current.feed,
      builder: (context, state) => switch (state.status) {
        NotificationsStatus.initial ||
        NotificationsStatus.loading => const AppLoader(),
        NotificationsStatus.error when state.isSignedOut => EmptyStateView(
          message: 'notifications.sign_in_prompt'.tr(),
          icon: Icons.lock_outline_rounded,
          actionLabel: 'auth.log_in_or_sign_up'.tr(),
          onAction: () => context.go(Routes.login),
        ),
        NotificationsStatus.error => ErrorView(
          message: state.failure?.localizedMessage,
          onRetry: () => context.read<NotificationsCubit>().load(),
        ),
        NotificationsStatus.loaded when state.feed.isEmpty => BrandedRefresh(
          onRefresh: () => context.read<NotificationsCubit>().refresh(),
          child: const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: NotificationsEmptyView(),
              ),
            ],
          ),
        ),
        NotificationsStatus.loaded => NotificationsList(feed: state.feed),
      },
    );
  }
}
