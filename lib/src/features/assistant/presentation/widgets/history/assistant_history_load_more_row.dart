import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/load_more_footer.dart';
import '../../../../../core/widgets/next_page_sentinel.dart';
import '../../cubit/assistant_history_cubit.dart';
import '../../cubit/assistant_history_state.dart';

/// The end-of-list sentinel while the server has more: in view it asks for
/// the next page ([NextPageSentinel]); the shared [LoadMoreFooter] — dots
/// while it loads, the retry pill after a failure — offline, "More will
/// load when you're back" instead (the history asks again by itself on
/// reconnect).
class AssistantHistoryLoadMoreRow extends StatelessWidget {
  const AssistantHistoryLoadMoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssistantHistoryCubit>();
    return NextPageSentinel<AssistantHistoryCubit, AssistantHistoryState>(
      onNextPage: cubit.loadMore,
      builder: (context, failed) => LoadMoreFooter(
        failed: failed,
        onRetry: () => cubit.loadMore(retry: true),
      ),
    );
  }
}
