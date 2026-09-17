import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// Pagination sentinel at the end of the list: the list only builds it when
/// the server has more, and building it (scrolling it into view) asks the
/// cubit for the next page. Shows a loader while that page is in flight and
/// a retry when the last attempt failed.
class NotificationsLoadMoreRow extends StatefulWidget {
  const NotificationsLoadMoreRow({super.key});

  @override
  State<NotificationsLoadMoreRow> createState() =>
      _NotificationsLoadMoreRowState();
}

class _NotificationsLoadMoreRowState extends State<NotificationsLoadMoreRow> {
  @override
  void initState() {
    super.initState();
    // After the frame: emitting during build would rebuild the list mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationsCubit>().loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: BlocSelector<NotificationsCubit, NotificationsState, bool>(
        // Loader by default (also for the frame before the request starts, so
        // "retry" never flashes); the retry shows only after a failed attempt.
        selector: (state) => state.loadMoreFailed,
        builder: (context, failed) => !failed
            ? const AppLoader(size: AppSize.s20)
            : Center(
                child: TextButton(
                  onPressed: () =>
                      context.read<NotificationsCubit>().loadMore(),
                  child: Text('retry'.tr()),
                ),
              ),
      ),
    );
  }
}
