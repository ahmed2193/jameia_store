import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// No topic matches the search: offers the support chat instead.
class SupportNoResults extends StatelessWidget {
  const SupportNoResults({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      art: HeroAssets.stateSearchEmpty,
      message: 'support.no_results_message'.tr(),
      actionLabel: 'support.chat_with_support'.tr(),
      onAction: () => context.push(Routes.imChat),
    );
  }
}
