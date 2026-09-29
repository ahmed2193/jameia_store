import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import 'assistant_copy_sheet.dart';
import 'assistant_rich_text_view.dart';
import 'assistant_stream_reveal.dart';

/// The assistant's words: a white bubble from the start edge (the avatar
/// beside it is the reply row's). Words streamed in this session reveal as
/// they arrive ([AssistantStreamReveal]); a stored reply is plain text.
/// Long-press (or the screen reader's custom action) copies it once it is
/// complete.
class AssistantTextBubble extends StatelessWidget {
  const AssistantTextBubble({
    super.key,
    required this.richText,
    this.streaming = false,
  });

  final AssistantRichText richText;

  /// Still being written: caret on, nothing to copy yet.
  final bool streaming;

  static const BorderRadiusDirectional _shape = BorderRadiusDirectional.only(
    topStart: Radius.circular(AppSize.r4),
    topEnd: Radius.circular(SuiRadius.bubble),
    bottomStart: Radius.circular(SuiRadius.bubble),
    bottomEnd: Radius.circular(SuiRadius.bubble),
  );

  @override
  Widget build(BuildContext context) {
    final copyText = streaming ? '' : richText.plainText;
    final canCopy = copyText.isNotEmpty;
    return Semantics(
      container: true,
      label: 'assistant.assistant_said'.tr(),
      customSemanticsActions: canCopy
          ? {
              CustomSemanticsAction(label: 'assistant.copy'.tr()): () =>
                  AssistantCopySheet.copy(context, copyText),
            }
          : null,
      child: GestureDetector(
        onLongPress: canCopy
            ? () => AssistantCopySheet.show(context, copyText)
            : null,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: _shape,
            boxShadow: AppShadows.low,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s10,
            ),
            child: AssistantStreamReveal(
              richText: richText,
              streaming: streaming,
              child: AssistantRichTextView(
                richText: richText,
                caret: streaming,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
