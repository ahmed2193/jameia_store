import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../cubit/unread_notifications_cubit.dart';
import '../widgets/notifications_app_bar.dart';
import '../widgets/notifications_body.dart';

/// Customer inbox (`GET /v1/notifications`, signed-in only). Composes the app
/// bar + body, keeps the app-global unread badge in step with what the
/// server said (never with the device copy), and surfaces the one-shot
/// outcomes: the "all read" toast, and failures the shared way — offline a
/// failed read or read mark only nudges the banner (the row flips back and
/// the banner already says why), a failed next page is the footer's.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static bool _shouldListen(
    NotificationsState previous,
    NotificationsState current,
  ) =>
      previous.knowsServerCount != current.knowsServerCount ||
      previous.feed.unreadCount != current.feed.unreadCount ||
      current.allMarkedRead;

  void _onState(BuildContext context, NotificationsState state) {
    if (state.knowsServerCount) {
      context.read<UnreadNotificationsCubit>().set(state.feed.unreadCount);
    }
    if (state.allMarkedRead) {
      showJameiaSnackBar(context, 'notifications.all_read_toast'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..load(),
      child: BlocListener<NotificationsCubit, NotificationsState>(
        listenWhen: _shouldListen,
        listener: _onState,
        child:
            const ScreenFailureListener<NotificationsCubit, NotificationsState>(
              child: Scaffold(
                backgroundColor: AppColors.white,
                appBar: NotificationsAppBar(),
                body: NotificationsBody(),
              ),
            ),
      ),
    );
  }
}
