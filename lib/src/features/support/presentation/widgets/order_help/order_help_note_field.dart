import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/hero_input_decoration.dart';
import '../../../domain/entities/support_ticket_draft.dart';
import '../../cubit/order_help_cubit.dart';

/// "Tell us more" — the customer's own words, optional (a ticket without
/// them describes the chosen issue itself), up to the API's limit. Keeps
/// its text across rebuilds; the cubit holds the draft, so a failed send
/// loses nothing.
class OrderHelpNoteField extends StatefulWidget {
  const OrderHelpNoteField({super.key});

  @override
  State<OrderHelpNoteField> createState() => _OrderHelpNoteFieldState();
}

class _OrderHelpNoteFieldState extends State<OrderHelpNoteField> {
  late final OrderHelpCubit _cubit;
  late final TextEditingController _controller;

  static const int _minLines = 3;
  static const int _maxLines = 6;

  @override
  void initState() {
    super.initState();
    // The page's cubit never changes under the field: read it once.
    _cubit = context.read<OrderHelpCubit>();
    _controller = TextEditingController(text: _cubit.state.request.note);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sending = context.select<OrderHelpCubit, bool>(
      (cubit) => cubit.state.isSending,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
      ),
      child: TextField(
        controller: _controller,
        enabled: !sending,
        minLines: _minLines,
        maxLines: _maxLines,
        maxLength: SupportTicketDraft.maxBodyLength,
        textCapitalization: TextCapitalization.sentences,
        onChanged: _cubit.setNote,
        style: AppTextStyles.itemTitle,
        cursorColor: AppColors.primaryText,
        decoration: HeroInputDecoration.outlined(
          hintText: 'support.help_note_hint'.tr(),
        ),
      ),
    );
  }
}
