import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';

/// A short confetti burst over the chat when a cart proposal is confirmed
/// — the moment the conversation turned into a fuller basket. Never on
/// open; nothing under reduced motion.
class AssistantCelebration extends StatelessWidget {
  const AssistantCelebration({super.key, required this.child});

  final Widget child;

  static const int _pieces = 28;
  static const Offset _origin = Offset(0.5, 0.55);
  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.accent4,
    AppColors.accent3,
    AppColors.martGreen,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AssistantChatCubit, AssistantChatState, int>(
      selector: (state) => state.cartRevision,
      builder: (context, revision) => ConfettiBurst(
        playKey: revision == 0 ? null : revision,
        colors: _colors,
        count: _pieces,
        origin: _origin,
        child: child,
      ),
    );
  }
}
