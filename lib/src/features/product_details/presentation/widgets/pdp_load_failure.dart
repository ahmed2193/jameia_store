import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/hero_secondary_button.dart';
import '../../../../core/widgets/hero_state_view.dart';
import '../../../../core/widgets/failure_verdict_builder.dart';
import '../../../../core/widgets/offline_inline_note.dart';

/// Under the tapped card when the product could not load — the offline
/// screen contract's verdict ([FailureVerdictBuilder]) in the page's own
/// layout: "Checking your connection…" while the app checks (a reload by
/// itself when the connection is there), offline the calm "loads as soon
/// as you're back online" line (the page asks again by itself on reconnect)
/// and "Try again"; any other failure, its message and retry.
class PdpLoadFailure extends StatelessWidget {
  const PdpLoadFailure({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  static const EdgeInsetsGeometry _padding = EdgeInsetsDirectional.only(
    bottom: AppSpacing.s24,
  );

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FailureVerdictBuilder(
    failure: failure,
    onRetry: onRetry,
    builder: (context, verdict) => switch (verdict) {
      FailureVerdict.checking => Padding(
        padding: _padding,
        child: OfflineInlineNote(
          message: 'connectivity.checking'.tr(),
          leading: const AppLoader.inline(size: AppSize.s24),
        ),
      ),
      FailureVerdict.offline => Padding(
        padding: _padding,
        child: Column(
          children: [
            OfflineInlineNote(
              message: 'connectivity.offline_state_message'.tr(),
            ),
            HeroSecondaryButton(label: 'retry'.tr(), onPressed: onRetry),
          ],
        ),
      ),
      FailureVerdict.unreachable => HeroStateView.error(onRetry: onRetry),
      FailureVerdict.error => HeroStateView.error(
        message: failure?.localizedMessage,
        onRetry: onRetry,
      ),
    },
  );
}
