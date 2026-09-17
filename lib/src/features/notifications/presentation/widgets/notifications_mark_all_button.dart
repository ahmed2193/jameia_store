import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// App-bar action: mark everything read. Enabled only while something is
/// unread, so a tap always means something.
class NotificationsMarkAllButton extends StatelessWidget {
  const NotificationsMarkAllButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotificationsCubit, NotificationsState, bool>(
      selector: (state) => state.isLoaded && state.feed.hasUnread,
      builder: (context, enabled) => IconButton(
        tooltip: 'notifications.mark_all_read'.tr(),
        icon: const Icon(Icons.done_all_rounded),
        color: AppColors.primaryText,
        disabledColor: AppColors.disabledText,
        onPressed: enabled
            ? () => context.read<NotificationsCubit>().markAllRead()
            : null,
      ),
    );
  }
}
