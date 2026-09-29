import 'package:flutter/widgets.dart';

import '../../config/theme/app_spacing.dart';
import '../domain/entities/data_freshness.dart';
import '../motion/collapse_reveal.dart';
import '../motion/motion.dart';
import 'connectivity_scope.dart';
import 'stale_age_pill.dart';

/// The one "Updated 12 minutes ago" note of a cached screen: shown over stale
/// data while offline or after its refresh failed
/// ([DataFreshness.noticeVisible]), nothing otherwise. It opens and folds
/// away by height + fade ([CollapseReveal], [AppMotion.fast] both ways —
/// docs/motion §9.4 #16), so the list below slides instead of jumping; a
/// screen that opens with the note shows it at once. Depends only on the
/// scope's "offline" aspect.
class StaleDataNotice extends StatelessWidget {
  const StaleDataNotice({
    super.key,
    required this.freshness,
    this.padding = defaultPadding,
  });

  static const EdgeInsetsGeometry defaultPadding =
      EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8);

  final DataFreshness freshness;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final fetchedAt = freshness.fetchedAt;
    final offline = ConnectivityScope.isOfflineOf(context);
    final visible =
        fetchedAt != null && freshness.noticeVisible(offline: offline);
    return CollapseReveal(
      visible: visible,
      duration: AppMotion.fast,
      // Folding, it keeps drawing the last pill it had.
      child: fetchedAt == null
          ? const SizedBox.shrink()
          : Padding(
              padding: padding,
              child: StaleAgePill(savedAt: fetchedAt),
            ),
    );
  }
}
