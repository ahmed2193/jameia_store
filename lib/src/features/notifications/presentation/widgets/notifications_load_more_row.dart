import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/load_more_footer.dart';
import '../../../../core/widgets/next_page_sentinel.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// Pagination sentinel at the end of the list: the list only builds it when
/// the server has more, and in view it asks for the next page
/// ([NextPageSentinel]). The shared [LoadMoreFooter]: dots while that page
/// is in flight, the retry pill when the last attempt failed — offline,
/// "More will load when you're back" instead (the inbox asks again by
/// itself on reconnect).
class NotificationsLoadMoreRow extends StatelessWidget {
  const NotificationsLoadMoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    return NextPageSentinel<NotificationsCubit, NotificationsState>(
      onNextPage: cubit.loadMore,
      builder: (context, failed) => LoadMoreFooter(
        failed: failed,
        onRetry: () => cubit.loadMore(retry: true),
      ),
    );
  }
}
