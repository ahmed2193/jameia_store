import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/assistant_history_cubit.dart';
import '../../cubit/assistant_history_state.dart';

/// The end-of-list sentinel while the server has more: building it asks for
/// the next page; a loader while it loads, a retry after a failure.
class AssistantHistoryLoadMoreRow extends StatefulWidget {
  const AssistantHistoryLoadMoreRow({super.key});

  @override
  State<AssistantHistoryLoadMoreRow> createState() =>
      _AssistantHistoryLoadMoreRowState();
}

class _AssistantHistoryLoadMoreRowState
    extends State<AssistantHistoryLoadMoreRow> {
  @override
  void initState() {
    super.initState();
    // After the frame: emitting during build would rebuild the list mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AssistantHistoryCubit>().loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: BlocSelector<AssistantHistoryCubit, AssistantHistoryState, bool>(
        selector: (state) => state.loadMoreFailed,
        builder: (context, failed) => !failed
            ? const AppLoader(size: AppSize.s20)
            : Center(
                child: TextButton(
                  onPressed: () =>
                      context.read<AssistantHistoryCubit>().loadMore(),
                  child: Text('assistant.retry'.tr()),
                ),
              ),
      ),
    );
  }
}
