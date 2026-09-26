import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../cubit/assistant_history_cubit.dart';
import '../cubit/assistant_history_state.dart';
import '../widgets/history/assistant_history_app_bar.dart';
import '../widgets/history/assistant_history_body.dart';

/// The customer's (or guest's) past assistant chats
/// (`GET /v1/assistant/conversations`). Picking one pops its id back to the
/// chat page, which opens it.
class AssistantHistoryPage extends StatelessWidget {
  const AssistantHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AssistantHistoryCubit>()..load(),
      // A failed first load is drawn by the body; a failed refresh is told.
      child: BlocListener<AssistantHistoryCubit, AssistantHistoryState>(
        listenWhen: (_, current) =>
            current.failure != null &&
            current.status == AssistantHistoryStatus.loaded &&
            current.failedAction == AssistantHistoryAction.refresh,
        listener: (context, state) {
          final failure = state.failure;
          if (failure != null) {
            showJameiaSnackBar(context, failure.localizedMessage);
          }
        },
        child: const Scaffold(
          backgroundColor: AppColors.white,
          appBar: AssistantHistoryAppBar(),
          body: AssistantHistoryBody(),
        ),
      ),
    );
  }
}
