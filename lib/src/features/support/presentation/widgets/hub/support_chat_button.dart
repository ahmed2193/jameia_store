import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// "Chat with support" — opens the rider / support chat.
class SupportChatButton extends StatelessWidget {
  const SupportChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
      ),
      child: AppButton(
        label: 'support.chat_with_support'.tr(),
        trailing: const HeroIcon(
          HeroIcons.chat,
          size: AppSize.s18,
          color: AppColors.brandForeground,
        ),
        onPressed: () => context.push(Routes.imChat),
      ),
    );
  }
}
