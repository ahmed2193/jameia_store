import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/hero_assets.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/empty_state_view.dart';

/// "Hero Pro is not available right now" — the store switched the
/// programme off or sells no plan. Pull to check again.
class ProUnavailableView extends StatelessWidget {
  const ProUnavailableView({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return BrandedRefresh(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyStateView(
              message: 'pro.unavailable'.tr(),
              art: HeroAssets.stateUnavailable,
            ),
          ),
        ),
      ),
    );
  }
}
