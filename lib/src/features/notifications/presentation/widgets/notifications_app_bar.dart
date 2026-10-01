import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/hero_title_bar.dart';
import '../cubit/notifications_cubit.dart';
import 'notifications_live_chip.dart';
import 'notifications_mark_all_button.dart';

/// Inbox title bar (the shared [HeroTitleBar]): the title with the unread
/// count under it while there is one, the live indicator and the
/// mark-all-read action.
class NotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const NotificationsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(HeroTitleBar.height);

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationsCubit, int>(
      (cubit) => cubit.state.isLoaded ? cubit.state.feed.unreadCount : 0,
    );
    return HeroTitleBar(
      title: 'notifications.title'.tr(),
      subtitle: unread == 0
          ? null
          : 'notifications.unread_badge'.tr(namedArgs: {'count': '$unread'}),
      actions: const [NotificationsLiveChip(), NotificationsMarkAllButton()],
    );
  }
}
