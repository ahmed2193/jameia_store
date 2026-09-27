import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/next_page_sentinel.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// Pagination sentinel at the end of the list: the list only builds it when
/// the server has more, and in view it asks for the next page
/// ([NextPageSentinel]). Shows a loader while that page is in flight and a
/// retry when the last attempt failed — offline, "More will load when
/// you're back" instead (the inbox asks again by itself on reconnect).
class NotificationsLoadMoreRow extends StatelessWidget {
  const NotificationsLoadMoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    return NextPageSentinel<NotificationsCubit, NotificationsState>(
      onNextPage: cubit.loadMore,
      builder: (context, failed) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: !failed
            ? const AppLoader(size: AppSize.s20)
            : Center(
                child: TextButton(
                  onPressed: () => cubit.loadMore(retry: true),
                  child: Text('retry'.tr()),
                ),
              ),
      ),
    );
  }
}
