import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/utils/failure_message.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../cubit/unread_notifications_cubit.dart';
import '../widgets/notifications_app_bar.dart';
import '../widgets/notifications_body.dart';

/// Customer inbox (`GET /v1/notifications`, signed-in only). Composes the app
/// bar + body, keeps the app-global unread badge in step with what the inbox
/// knows, and surfaces the one-shot outcomes (toast, request failures).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static bool _shouldListen(
    NotificationsState previous,
    NotificationsState current,
  ) =>
      previous.status != current.status ||
      previous.feed.unreadCount != current.feed.unreadCount ||
      current.failure != null ||
      current.allMarkedRead;

  void _onState(BuildContext context, NotificationsState state) {
    if (state.isLoaded) {
      context.read<UnreadNotificationsCubit>().set(state.feed.unreadCount);
    }
    if (state.allMarkedRead) {
      showJameiaSnackBar(context, 'notifications.all_read_toast'.tr());
    }
    final failure = state.failure;
    // A failed first load is rendered inline by the body, not toasted.
    if (failure == null || state.status == NotificationsStatus.error) return;
    showJameiaSnackBar(
      context,
      state.failedAction == NotificationsAction.loadMore
          ? 'notifications.load_more_failed'.tr()
          : failure.localizedMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..load(),
      child: BlocListener<NotificationsCubit, NotificationsState>(
        listenWhen: _shouldListen,
        listener: _onState,
        child: const Scaffold(
          backgroundColor: AppColors.white,
          appBar: NotificationsAppBar(),
          body: NotificationsBody(),
        ),
      ),
    );
  }
}
