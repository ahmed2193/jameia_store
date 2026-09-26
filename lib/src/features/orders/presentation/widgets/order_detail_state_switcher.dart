import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/jameia_state_view.dart';

/// The state swap the order detail pages (tracking, invoice, review) share:
/// the loaded [content] when there is one, else — when [failed] — the
/// sign-in prompt (signed out) or the error view with a retry, else the
/// loader. It fades through only when that bucket changes: a poll or an edit
/// that updates the content keeps the key, so the body updates in place.
class OrderDetailStateSwitcher extends StatelessWidget {
  const OrderDetailStateSwitcher({
    super.key,
    required this.content,
    required this.failed,
    required this.isSignedOut,
    required this.onRetry,
    this.errorMessage,
  });

  /// The page body, or `null` while there is nothing to show yet.
  final Widget? content;

  /// The page's load failed (its status is `error`).
  final bool failed;
  final bool isSignedOut;

  /// Defaults to the kit's generic "something went wrong".
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final content = this.content;
    final (_Bucket bucket, Widget child) = content != null
        ? (_Bucket.content, content)
        : failed
        ? (
            _Bucket.error,
            isSignedOut
                ? JameiaStateView.signedOut(
                    message: 'orders.sign_in_required'.tr(),
                  )
                : JameiaStateView.error(
                    message: errorMessage,
                    onRetry: onRetry,
                  ),
          )
        : (_Bucket.loading, const AppLoader());
    return FadeThroughSwitcher(
      stateKey: bucket,
      alignment: AlignmentDirectional.topCenter,
      child: child,
    );
  }
}

enum _Bucket { loading, error, content }
