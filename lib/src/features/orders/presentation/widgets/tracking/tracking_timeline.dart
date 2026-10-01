import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/order_timeline.dart';
import 'tracking_timeline_row.dart';

/// "Order updates": every status the order went through with its time,
/// folded behind a row that opens it in place (height, then fade) — the
/// detail a customer looks for when something took long, out of the way
/// otherwise. Takes no space when the order has no history yet.
class TrackingTimeline extends StatefulWidget {
  const TrackingTimeline({super.key, required this.timeline});

  final OrderTimeline timeline;

  @override
  State<TrackingTimeline> createState() => _TrackingTimelineState();
}

class _TrackingTimelineState extends State<TrackingTimeline> {
  static const double _openTurns = 0.5;

  bool _open = false;

  void _toggle() {
    Haptics.pick();
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.timeline.events;
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'orders.updates_title'.tr(),
                      style: AppTextStyles.itemTitle,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? _openTurns : 0,
                    duration: MotionGuard.duration(context, AppMotion.medium),
                    curve: AppMotion.signature,
                    child: const HeroIcon(
                      HeroIcons.chevronDown,
                      size: AppSize.s24,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        CollapseReveal(
          visible: _open,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.s4,
              bottom: AppSpacing.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < events.length; i++)
                  TrackingTimelineRow(
                    event: events[i],
                    latest: i == events.length - 1,
                    last: i == events.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
