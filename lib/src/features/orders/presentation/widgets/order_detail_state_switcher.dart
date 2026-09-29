import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../../../core/widgets/hero_state_view.dart';

/// The state swap the order detail pages (tracking, invoice, review) share:
/// the loaded [content] when there is one, else — when the load [failure]d —
/// the sign-in prompt (signed out), the "not there any more" plate for an
/// order that is gone ([notFound]: a way back, never a Retry that cannot
/// work), or [FailureView] (a lost connection: "Checking your connection…"
/// until the app knows, then a reload by itself or "No connection", which
/// loads the page when the connection returns; anything else: the error
/// with a retry), else the [loading] placeholder. It fades through only
/// when that bucket changes: a poll or an edit that updates the content
/// keeps the key, so the body updates in place.
class OrderDetailStateSwitcher extends StatelessWidget {
  const OrderDetailStateSwitcher({
    super.key,
    required this.content,
    required this.failure,
    required this.isSignedOut,
    required this.onRetry,
    this.errorMessage,
    this.loading = const AppLoader(),
    this.notFound = false,
    this.onBack,
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

  /// Shown while the first read is on the way (a disc, or the page's
  /// skeleton).
  final Widget loading;

  /// The order is gone (404): [errorMessage] with a way [onBack].
  final bool notFound;
  final VoidCallback? onBack;

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
                : notFound
                ? HeroStateView(
                    message: errorMessage ?? 'orders.not_found'.tr(),
                    icon: Icons.receipt_long_outlined,
                    actionLabel: onBack == null
                        ? null
                        : 'orders.back_to_orders'.tr(),
                    onAction: onBack,
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
        : (_Bucket.loading, loading);
    return FadeThroughSwitcher(
      stateKey: bucket,
      alignment: AlignmentDirectional.topCenter,
      child: child,
    );
  }
}

enum _Bucket { loading, error, content }
