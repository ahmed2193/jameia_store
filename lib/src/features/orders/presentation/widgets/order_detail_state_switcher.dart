import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../../../core/widgets/hero_state_view.dart';

/// The state swap the order detail pages (tracking, invoice, review) share:
/// the loaded [content] when there is one, else — when the load [failure]d —
/// the sign-in prompt (signed out) or [FailureView] (a lost connection:
/// "Checking your connection…" until the app knows, then a reload by itself
/// or "No connection", which loads the page when the connection returns;
/// anything else: the error with a retry), else the loader. It fades
/// through only when that bucket changes: a poll or an edit that updates
/// the content keeps the key, so the body updates in place.
class OrderDetailStateSwitcher extends StatelessWidget {
  const OrderDetailStateSwitcher({
    super.key,
    required this.content,
    required this.failure,
    required this.isSignedOut,
    required this.onRetry,
    this.errorMessage,
  });

  /// The page body, or `null` while there is nothing to show yet.
  final Widget? content;

  /// Why the page could not load; `null` while it loads or shows.
  final Failure? failure;
  final bool isSignedOut;

  /// Replaces the failure's own message (a page that knows better, e.g. an
  /// order that no longer exists).
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final content = this.content;
    final failure = this.failure;
    final (_Bucket bucket, Widget child) = content != null
        ? (_Bucket.content, content)
        : failure != null
        ? (
            _Bucket.error,
            isSignedOut
                ? HeroStateView.signedOut(
                    message: 'orders.sign_in_required'.tr(),
                  )
                : FailureView(
                    failure: failure,
                    onRetry: onRetry,
                    errorBuilder: (message) => HeroStateView.error(
                      message: errorMessage ?? message,
                      onRetry: onRetry,
                    ),
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
