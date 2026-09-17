import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// App-bar title with the unread caption underneath while there is one.
class NotificationsTitle extends StatelessWidget {
  const NotificationsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'notifications.title'.tr(),
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: AppTextStyles.medium,
          ),
        ),
        BlocSelector<NotificationsCubit, NotificationsState, int>(
          selector: (state) => state.isLoaded ? state.feed.unreadCount : 0,
          builder: (context, unreadCount) {
            if (unreadCount == 0) return const SizedBox.shrink();
            return Text(
              'notifications.unread_badge'.tr(
                namedArgs: {'count': '$unreadCount'},
              ),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            );
          },
        ),
      ],
    );
  }
}
