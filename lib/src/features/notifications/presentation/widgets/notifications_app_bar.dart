import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import 'notifications_live_chip.dart';
import 'notifications_mark_all_button.dart';
import 'notifications_title.dart';

/// Inbox app bar: title + unread caption, the live indicator and the
/// mark-all-read action.
class NotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const NotificationsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      title: const NotificationsTitle(),
      actions: const [
        NotificationsLiveChip(),
        NotificationsMarkAllButton(),
        SizedBox(width: AppSpacing.s4),
      ],
    );
  }
}
