import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../cubit/assistant_history_cubit.dart';
import '../cubit/assistant_history_state.dart';
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
      // A failed first load is drawn by the body and a failed next page by
      // the footer; a failed refresh — or the check behind a saved list — is
      // told (offline: the banner is nudged instead).
      child:
          ScreenFailureListener<AssistantHistoryCubit, AssistantHistoryState>(
            child: Scaffold(
              backgroundColor: AppColors.white,
              appBar: HeroTitleBar(title: 'assistant.history'.tr()),
              body: const AssistantHistoryBody(),
            ),
          ),
    );
  }
}
