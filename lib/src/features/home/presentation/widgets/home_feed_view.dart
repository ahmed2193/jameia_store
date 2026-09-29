import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/motion/entrance_cascade_item.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_announcement_ticker.dart';
import 'home_greeting_strip.dart';
import 'home_layout.dart';
import 'home_pro_banner.dart';
import 'home_section_view.dart';
import 'home_slides_carousel.dart';

/// The loaded home feed, one sliver group under the header ([HomeFrame]),
/// in the backend's order: "Updated … ago" over a saved copy
/// (offline / failed refresh) → a hello for the hour → announcement
/// ticker → hero banners → the ordered content blocks → Pro banner. Blocks are
/// built lazily while scrolling. The ones on screen when the feed first
/// arrives cascade in under the header (the frame's `EntranceCascade`); the
/// rest — and any block scrolled back to — are simply there. The frame puts
/// the back-to-top button over it, and confetti from a card flies over it.
class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key, required this.feed, required this.bootstrap});

  final HomeFeed feed;
  final HomeBootstrap bootstrap;

  /// The cascade: greeting, ticker, banners, then the blocks in order.
  static const int _tickerOrder = 1;
  static const int _slidesOrder = 2;
  static const int _sectionsOrder = 3;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // Selects only the freshness: never rebuilds the feed.
        const SliverToBoxAdapter(
          child: ScreenStaleNotice<HomeCubit, HomeState>(),
        ),
        const SliverToBoxAdapter(
          child: EntranceCascadeItem(index: 0, child: HomeGreetingStrip()),
        ),
        if (feed.announcements.isNotEmpty)
          SliverToBoxAdapter(
            child: EntranceCascadeItem(
              index: _tickerOrder,
              child: HomeAnnouncementTicker(items: feed.announcements),
            ),
          ),
        if (feed.slides.isNotEmpty)
          SliverToBoxAdapter(
            child: EntranceCascadeItem(
              index: _slidesOrder,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: HomeLayout.blockGap,
                ),
                child: HomeSlidesCarousel(slides: feed.slides),
              ),
            ),
          ),
        SliverList.builder(
          itemCount: feed.sections.length,
          itemBuilder: (context, index) => EntranceCascadeItem(
            key: ValueKey(feed.sections[index].id),
            index: index + _sectionsOrder,
            child: HomeSectionView(section: feed.sections[index]),
          ),
        ),
        if (bootstrap.pro.enabled)
          SliverToBoxAdapter(
            child: EntranceCascadeItem(
              index: feed.sections.length + _sectionsOrder,
              child: HomeProBanner(
                pro: bootstrap.pro,
                onTap: () => context.push(Routes.proMembership),
              ),
            ),
          ),
        // Clears the shell's bottom bar.
        const SliverToBoxAdapter(child: SizedBox(height: AppSize.s80)),
      ],
    );
  }
}
