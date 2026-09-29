import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/navigation/navigation.dart';

/// Long-press menu of a bubble: Copy.
class AssistantCopySheet extends StatelessWidget {
  const AssistantCopySheet({super.key, required this.text});

  final String text;

  /// Opens the sheet for [text]; nothing to copy → nothing opens.
  static Future<void> show(BuildContext context, String text) async {
    if (text.trim().isEmpty) return;
    await showHeroBottomSheet<void>(
      context,
      builder: (_) => AssistantCopySheet(text: text),
    );
  }

  /// Copies [text] and confirms it.
  static Future<void> copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showHeroSnackBar(
      context,
      'assistant.copied'.tr(),
      tone: HeroSnackTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
        child: ListTile(
          leading: const Icon(Icons.copy_rounded, color: AppColors.primaryText),
          title: Text('assistant.copy'.tr(), style: AppTextStyles.headingSmall),
          onTap: () {
            // The sheet's own context dies with it: confirm from the page's.
            final navigator = Navigator.of(context);
            navigator.pop();
            copy(navigator.context, text);
          },
        ),
      ),
    );
  }
}
