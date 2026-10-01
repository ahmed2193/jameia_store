import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_dot_loader.dart';
import '../../cubit/rider_chat_cubit.dart';

/// "Ali is typing…" with the brand's two dots, while the rider writes an
/// answer; read out once as it appears.
class RiderChatTyping extends StatelessWidget {
  const RiderChatTyping({super.key, required this.riderName});

  final String riderName;

  @override
  Widget build(BuildContext context) {
    final typing = context.select<RiderChatCubit, bool>(
      (cubit) => cubit.state.chat.riderTyping,
    );
    return CollapseReveal(
      visible: typing,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.gutter,
          AppSpacing.s4,
          AppSpacing.gutter,
          AppSpacing.s8,
        ),
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const ExcludeSemantics(
                child: BrandedDotLoader(size: AppSize.s18),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'orders.chat_typing'.tr(namedArgs: {'rider': riderName}),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
