import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../cubit/unread_notifications_cubit.dart';
import '../cubit/unread_notifications_state.dart';

/// Small "Live" pill in the app bar while the SSE connection is listened to
/// (state owned by the app-global badge cubit); nothing otherwise.
class NotificationsLiveChip extends StatelessWidget {
  const NotificationsLiveChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      UnreadNotificationsCubit,
      UnreadNotificationsState,
      bool
    >(
      selector: (state) => state.isLive,
      builder: (context, isLive) {
        if (!isLive) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsetsDirectional.only(end: AppSpacing.s4),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent2Light,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSize.s6,
                height: AppSize.s6,
                decoration: const BoxDecoration(
                  color: AppColors.accent2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                'notifications.live_connected'.tr(),
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.accent2Dark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
