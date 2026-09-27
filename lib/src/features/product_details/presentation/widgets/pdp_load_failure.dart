import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/offline_inline_note.dart';

/// Under the tapped card when the product could not load: offline, the calm
/// "loads as soon as you're back online" line (the page asks again by itself
/// on reconnect) and "Try again"; any other failure, its message and retry.
class PdpLoadFailure extends StatelessWidget {
  const PdpLoadFailure({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (failure is! NetworkFailure) {
      return ErrorView(message: failure?.localizedMessage, onRetry: onRetry);
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      child: Column(
        children: [
          OfflineInlineNote(message: 'connectivity.offline_state_message'.tr()),
          AppOutlineButton(label: 'retry'.tr(), onPressed: onRetry),
        ],
      ),
    );
  }
}
