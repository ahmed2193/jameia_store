import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/rolling_number_text.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../domain/entities/courier_stage.dart';
import '../../cubit/courier_tracking_cubit.dart';
import '../../cubit/courier_tracking_state.dart';
import 'live_map_arrived_title.dart';

/// The panel's headline: "Arriving in" over the minutes to the door, the
/// digits rolling as they change; under it where the ride stands ("Your
/// rider is heading to the store…") — "Locating your rider…" while the feed
/// is quiet. At the door the headline turns into [LiveMapArrivedTitle].
/// Rebuilds only when the minutes, the stage or the quiet change.
class LiveMapEta extends StatelessWidget {
  const LiveMapEta({super.key});

  static bool _changed(CourierTrackingState before, CourierTrackingState now) =>
      before.progress?.minutesLeft != now.progress?.minutesLeft ||
      before.stage != now.stage ||
      before.stale != now.stale;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourierTrackingCubit, CourierTrackingState>(
      buildWhen: _changed,
      builder: (context, state) {
        final stage = state.stage ?? CourierStage.assigning;
        final minutes = state.progress?.minutesLeft;
        final arrived = stage == CourierStage.arrived;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizeFadeSwitcher(
              stateKey: arrived,
              child: arrived
                  ? const LiveMapArrivedTitle()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'orders.eta_arriving_label'.tr(),
                          style: AppTextStyles.meta,
                        ),
                        minutes == null
                            ? Text(
                                'orders.live_eta_pending'.tr(),
                                style: AppTextStyles.displayMedium,
                              )
                            : RollingNumberText(
                                value: minutes,
                                // The rolling digits fill the text; the
                                // target minutes pick the plural form.
                                text: (number) =>
                                    'orders.eta_minutes_count'.plural(
                                      minutes,
                                      namedArgs: {'minutes': number},
                                    ),
                                style: AppTextStyles.displayMedium,
                              ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.s4),
            SizeFadeSwitcher(
              stateKey: (stage, state.stale),
              // Read out as it changes (the rolling minutes above are not).
              child: Semantics(
                liveRegion: true,
                child: Text(
                  (state.stale ? 'orders.live_locating' : stage.labelKey).tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
