import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/entrance_cascade.dart';
import '../../../../core/motion/sliver_state_fade.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/back_to_top_overlay.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../cubit/home_cubit.dart';
import 'home_confetti.dart';
import 'home_header_sliver.dart';
import 'home_layout.dart';
import 'home_loading_view.dart';

/// The one scroll frame of every Home state: the real header on top, then
/// [body] — the skeleton, the failure, the empty plate or the feed (one
/// sliver each). The header keeps its place and its element across those
/// swaps, so its one-shot cues (the "pro" tag, the ETA pill, the bell, the
/// typed search hint) play once per real change, never again because the
/// state below it moved (App A #25 P22). The feed's entrance scope sits
/// here too: it opens only when the feed first shows ([loaded]), and a
/// reload that passes through the skeleton does not replay it — the body
/// then fades in instead of snapping ([SliverStateFade]).
class HomeFrame extends StatelessWidget {
  const HomeFrame({
    super.key,
    required this.bootstrap,
    required this.loaded,
    required this.body,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  /// The launch snapshot (`GET /v1/init`); empty until it lands.
  final HomeBootstrap bootstrap;

  /// The feed (or the empty plate) is showing: the entrance may open.
  final bool loaded;

  /// The state's one sliver under the header.
  final Widget body;

  /// The skeleton holds still; the feed and the empty plate can be pulled.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: BackToTopOverlay(
        margin: HomeLayout.gutter,
        child: HomeConfetti(
          child: BrandedRefresh(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            child: EntranceCascade(
              ready: loaded,
              child: CustomScrollView(
                physics: physics,
                slivers: [
                  // Only this sliver rebuilds when the default address or the
                  // unread badge changes.
                  HomeHeaderSliver(bootstrap: bootstrap),
                  SliverStateFade(
                    stateKey: body.runtimeType,
                    arrived: body is! HomeLoadingView,
                    sliver: body,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
