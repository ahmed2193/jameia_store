import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/data_freshness.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../../core/widgets/info_pill.dart';
import '../../cubit/order_tracking_cubit.dart';

/// "Last known status · 5:55 PM" under the status while it is not live —
/// offline (no poll runs) or after the last check failed — so an old status
/// is never read as the order's live state. Not on a finished order: its
/// status is final. Opens and folds in place like the page's other notices;
/// only a freshness or connection change rebuilds it.
class TrackingLastKnownNote extends StatelessWidget {
  const TrackingLastKnownNote({super.key, required this.order});

  final OrderEntity order;

  /// Today: the clock time; an older status also says its day.
  static String _asOf(String languageCode, DateTime at) {
    final local = at.toLocal();
    return Formatters.isolate(
      DateUtils.isSameDay(local, DateTime.now())
          ? Formatters.clock(languageCode, local)
          : Formatters.dateTime(languageCode, local),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offline = ConnectivityScope.isOfflineOf(context);
    final freshness = context.select<OrderTrackingCubit, DataFreshness>(
      (cubit) => cubit.state.freshness,
    );
    final at = freshness.fetchedAt;
    return CollapseReveal(
      visible: !order.isTerminal && freshness.isLastKnown(offline: offline),
      child: at == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.s12,
                AppSpacing.gutter,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: InfoPill(
                  icon: Icons.history_rounded,
                  text: 'connectivity.order_status_as_of'.tr(
                    namedArgs: {'time': _asOf(context.locale.languageCode, at)},
                  ),
                ),
              ),
            ),
    );
  }
}
