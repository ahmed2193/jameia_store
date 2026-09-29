import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import 'delivery_code_editor_card.dart';
import 'delivery_code_hero_card.dart';
import 'delivery_code_tips_card.dart';

/// The loaded delivery-code screen: the saved code, the editor for a new one
/// and how the code works. The cards rise in once ([EntranceCascade]), not
/// under the page's own push.
class DeliveryCodeContent extends StatelessWidget {
  const DeliveryCodeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const EntranceCascade(
      child: ContentClamp(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EntranceCascadeItem(index: 0, child: DeliveryCodeHeroCard()),
              SizedBox(height: AppSpacing.s16),
              EntranceCascadeItem(index: 1, child: DeliveryCodeEditorCard()),
              SizedBox(height: AppSpacing.s16),
              EntranceCascadeItem(index: 2, child: DeliveryCodeTipsCard()),
            ],
          ),
        ),
      ),
    );
  }
}
