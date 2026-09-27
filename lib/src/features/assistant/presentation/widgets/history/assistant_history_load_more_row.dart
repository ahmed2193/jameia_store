import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/next_page_sentinel.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/assistant_history_cubit.dart';
import '../../cubit/assistant_history_state.dart';

/// The end-of-list sentinel while the server has more: in view it asks for
/// the next page ([NextPageSentinel]); a loader while it loads, a retry
/// after a failure — offline, "More will load when you're back" instead
/// (the history asks again by itself on reconnect).
class AssistantHistoryLoadMoreRow extends StatelessWidget {
  const AssistantHistoryLoadMoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssistantHistoryCubit>();
    return NextPageSentinel<AssistantHistoryCubit, AssistantHistoryState>(
      onNextPage: cubit.loadMore,
      builder: (context, failed) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: !failed
            ? const AppLoader(size: AppSize.s20)
            : Center(
                child: TextButton(
                  onPressed: () => cubit.loadMore(retry: true),
                  child: Text('assistant.retry'.tr()),
                ),
              ),
      ),
    );
  }
}
