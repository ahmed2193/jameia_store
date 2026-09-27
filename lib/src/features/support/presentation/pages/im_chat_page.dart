import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../cubit/im_chat_cubit.dart';
import '../widgets/chat/im_chat_app_bar.dart';
import '../widgets/chat/im_chat_body.dart';

/// Hero rider chat — `im_user_rider_chat`: the rider's title bar, the
/// message thread, the quick replies and the composer. Offline (no IM
/// socket): the thread lives in the body's state.
class ImChatPage extends StatelessWidget {
  const ImChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ImChatCubit>()..load(),
      child: BlocSelector<ImChatCubit, ImChatState, String>(
        selector: (state) => state.riderName,
        builder: (context, riderName) => Scaffold(
          backgroundColor: AppColors.mediumBackground,
          appBar: ImChatAppBar(riderName: riderName),
          body: const SafeArea(
            top: false,
            child: ContentClamp(child: ImChatBody()),
          ),
        ),
      ),
    );
  }
}
