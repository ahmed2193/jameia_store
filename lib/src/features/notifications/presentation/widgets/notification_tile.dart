import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubit/notifications_cubit.dart';
import 'notification_kind_icon.dart';
import 'notification_time_text.dart';

/// One inbox row. Tapping marks it read (optimistic, in the cubit) and
/// follows the deep link the backend attached: an order opens tracking, a
/// support ticket opens customer service, anything else just stays.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification});

  final NotificationEntity notification;

  static const int _bodyMaxLines = 2;
  static const int _titleMaxLines = 2;

  void _onTap(BuildContext context) {
    context.read<NotificationsCubit>().markRead(notification.id);
    if (notification.hasOrder) {
      context.push(Routes.orderTracking, extra: notification.orderId);
    } else if (notification.hasTicket) {
      context.push(Routes.customerService);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final unread = notification.isUnread;
    return InkWell(
      onTap: () => _onTap(context),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationKindIcon(kind: notification.kind),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.titleFor(languageCode),
                    maxLines: _titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: unread
                          ? AppTextStyles.bold
                          : AppTextStyles.medium,
                      color: unread
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    notification.bodyFor(languageCode),
                    maxLines: _bodyMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  NotificationTimeText(time: notification.createdAt),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: AppSpacing.s8),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s6),
                child: Container(
                  width: AppSize.s8,
                  height: AppSize.s8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
