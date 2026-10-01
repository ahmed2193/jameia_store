import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../../core/widgets/hero_sheet_handle.dart';

/// Long-press menu of a bubble: the sheet handle and a "Copy" row.
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeroSheetHandle(),
          const SizedBox(height: AppSpacing.s8),
          EntranceCascadeItem.single(
            child: HeroListRow(
              icon: HeroIcons.copy,
              title: 'assistant.copy'.tr(),
              showChevron: false,
              onTap: () {
                // The sheet's own context dies with it: confirm from the
                // page's.
                final navigator = Navigator.of(context);
                navigator.pop();
                copy(navigator.context, text);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }
}
