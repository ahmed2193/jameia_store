import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import 'delivery_code_editor_card.dart';
import 'delivery_code_hero_card.dart';
import 'delivery_code_tips_card.dart';

/// The delivery-code screen: the saved code, the editor for a new one and
/// how the code works. The cards rise in once.
class DeliveryCodeBody extends StatelessWidget {
  const DeliveryCodeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentClamp(
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
            StaggerEntrance(index: 0, child: DeliveryCodeHeroCard()),
            SizedBox(height: AppSpacing.s16),
            StaggerEntrance(index: 1, child: DeliveryCodeEditorCard()),
            SizedBox(height: AppSpacing.s16),
            StaggerEntrance(index: 2, child: DeliveryCodeTipsCard()),
          ],
        ),
      ),
    );
  }
}
