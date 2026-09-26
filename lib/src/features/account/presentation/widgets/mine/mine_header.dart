import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/auth_customer_entity.dart';
import 'mine_docking_avatar.dart';
import 'mine_header_background.dart';
import 'mine_header_compact_title.dart';
import 'mine_header_details.dart';
import 'mine_header_metrics.dart';
import 'mine_scan_action.dart';

/// The Mine header at one point of its collapse ([shrinkOffset]):
///
///   * the background tint fades to white and a soft shadow comes in;
///   * the avatar shrinks to half size and docks at the start of the bar
///     (over the first 60% of the collapse);
///   * the name / phone block rides up under the bar while its ink fades
///     (first half);
///   * the compact name fades in beside the docked avatar (last 30%).
///
/// The whole header opens the profile editor (a guest: the login page); the
/// scan action opens the delivery code.
class MineHeader extends StatelessWidget {
  const MineHeader({
    super.key,
    required this.customer,
    required this.metrics,
    required this.shrinkOffset,
  });

  static const Interval _dock = Interval(0, 0.6);
  static const Interval _detailsOut = Interval(0, 0.5);
  static const Interval _compactIn = Interval(0.7, 1);

  final AuthCustomerEntity? customer;
  final MineHeaderMetrics metrics;
  final double shrinkOffset;

  @override
  Widget build(BuildContext context) {
    final progress = metrics.progress(shrinkOffset);
    final signedIn = customer != null;
    final clipTop = metrics.topInset + MineHeaderMetrics.toolbar;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Semantics(
        button: true,
        hint: (signedIn ? 'account.edit_profile' : 'account.sign_in').tr(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              context.push(signedIn ? Routes.profileEdit : Routes.login),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MineHeaderBackground(progress: progress),
              // The details scroll up under the bar and are cut at its edge.
              PositionedDirectional(
                top: clipTop,
                start: 0,
                end: 0,
                bottom: 0,
                child: ClipRect(
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        top: metrics.detailsTop - shrinkOffset - clipTop,
                        start: MineHeaderMetrics.sideMargin,
                        end: MineHeaderMetrics.sideMargin,
                        child: MineHeaderDetails(
                          customer: customer,
                          fade: 1 - _detailsOut.transform(progress),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: metrics.topInset,
                start: MineHeaderMetrics.compactStart,
                end: MineHeaderMetrics.compactEnd,
                height: MineHeaderMetrics.toolbar,
                child: MineHeaderCompactTitle(
                  customer: customer,
                  reveal: _compactIn.transform(progress),
                ),
              ),
              PositionedDirectional(
                top: metrics.topInset + MineHeaderMetrics.avatarTop,
                start: MineHeaderMetrics.sideMargin,
                end: MineHeaderMetrics.sideMargin,
                child: MineDockingAvatar(
                  customer: customer,
                  dock: _dock.transform(progress),
                ),
              ),
              PositionedDirectional(
                top:
                    metrics.topInset +
                    (MineHeaderMetrics.toolbar - MineHeaderMetrics.action) / 2,
                end: MineHeaderMetrics.sideMargin,
                child: const MineScanAction(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
