import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/failure_view.dart';
import '../../cubit/courier_tracking_cubit.dart';
import '../../cubit/courier_tracking_state.dart';
import 'live_map_scene.dart';
import 'live_map_top_bar.dart';

/// Reading the ride (the Hero loader), the ride on its map ([LiveMapScene]),
/// or why it could not be read, with a retry — fading through as it goes.
/// The top bar (the way back, the Live pill) floats over all three and
/// stays put: it is the same on each, so it takes no part in the swap.
/// Rebuilds when the status or the ride change, never per fix.
class LiveMapBody extends StatelessWidget {
  const LiveMapBody({super.key});

  static bool _changed(CourierTrackingState before, CourierTrackingState now) =>
      before.status != now.status || before.trip != now.trip;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourierTrackingCubit, CourierTrackingState>(
      buildWhen: _changed,
      builder: (context, state) {
        final trip = state.trip;
        return Stack(
          children: [
            FadeThroughSwitcher(
              stateKey: state.status,
              child: switch (state.status) {
                CourierTrackingStatus.live when trip != null => LiveMapScene(
                  trip: trip,
                ),
                CourierTrackingStatus.failed => SafeArea(
                  child: FailureView(
                    failure: state.failure ?? const UnexpectedFailure(),
                    onRetry: context.read<CourierTrackingCubit>().retry,
                  ),
                ),
                _ => const Center(child: AppLoader()),
              },
            ),
            const PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: LiveMapTopBar(),
            ),
          ],
        );
      },
    );
  }
}
